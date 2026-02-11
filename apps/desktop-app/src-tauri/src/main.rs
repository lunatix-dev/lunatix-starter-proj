#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use tauri::Manager;
use std::sync::Mutex;
use tauri::api::process::{Command, CommandChild};

// State to hold the child process handle and current API URL
struct ServerState {
    child: Mutex<Option<CommandChild>>,
    api_url: Mutex<String>,
}

#[tauri::command]
fn get_api_url(state: tauri::State<ServerState>) -> String {
    state.api_url.lock().unwrap().clone()
}

#[tauri::command]
fn set_remote_mode(state: tauri::State<ServerState>, url: String) {
    println!("Switching to remote mode: {}", url);
    // Kill local server if running
    if let Some(child) = state.child.lock().unwrap().take() {
        let _ = child.kill();
        println!("Killed local sidecar");
    }
    *state.api_url.lock().unwrap() = url;
}

#[tauri::command]
fn set_standalone_mode(state: tauri::State<ServerState>) -> Result<(), String> {
    println!("Switching to standalone mode");
    let mut child_lock = state.child.lock().unwrap();
    if child_lock.is_some() {
        println!("Sidecar already running");
        return Ok(()); // already running
    }

    let (mut rx, child) = Command::new_sidecar("cpp-server")
        .map_err(|e| e.to_string())?
        .args(["--port", "8080"])
        .spawn()
        .map_err(|e| e.to_string())?;

    println!("Spawned sidecar with PID {}", child.pid());

    // Pipe output to stdout
    tauri::async_runtime::spawn(async move {
        while let Some(event) = rx.recv().await {
             match event {
                tauri::api::process::CommandEvent::Stdout(line) => println!("[cpp-server] {}", line),
                tauri::api::process::CommandEvent::Stderr(line) => eprintln!("[cpp-server] {}", line),
                _ => {}
            }
        }
    });

    *child_lock = Some(child);
    *state.api_url.lock().unwrap() = "http://localhost:8080".into();
    Ok(())
}

fn main() {
    let server_state = ServerState {
        child: Mutex::new(None),
        api_url: Mutex::new("http://localhost:8080".into()),
    };

    tauri::Builder::default()
        .manage(server_state)
        .invoke_handler(tauri::generate_handler![
            get_api_url,
            set_remote_mode,
            set_standalone_mode,
        ])
        .setup(|app| {
            // Default: start in standalone mode
            let state = app.state::<ServerState>();

            // Check if we are in standalone mode
            if std::env::var("LUNATIX_STANDALONE") == Ok("1".to_string()) {
                println!("LUNATIX_STANDALONE=1 detected. Attempting to spawn sidecar...");
                // Check if binary exists (helpful for debugging)
                // But verify sidecar command
                if let Ok(cmd) = Command::new_sidecar("cpp-server") {
                     match cmd.args(["--port", "8080"]).spawn() {
                        Ok((mut rx, child)) => {
                            println!("App setup: spawned sidecar PID {}", child.pid());
                            
                            tauri::async_runtime::spawn(async move {
                                while let Some(event) = rx.recv().await {
                                    match event {
                                        tauri::api::process::CommandEvent::Stdout(line) => println!("[cpp-server] {}", line),
                                        tauri::api::process::CommandEvent::Stderr(line) => eprintln!("[cpp-server] {}", line),
                                        _ => {}
                                    }
                                }
                            });

                            *state.child.lock().unwrap() = Some(child);
                        }
                        Err(e) => {
                             eprintln!("Failed to spawn sidecar: {}", e);
                             println!("Falling back to external server");
                        }
                     }
                } else {
                     eprintln!("Sidecar binary not found or configuration error.");
                     println!("Falling back to external server");
                }
            } else {
                println!("LUNATIX_STANDALONE not set. Skipping sidecar spawn. Connecting to external server.");
            }
            Ok(())
        })
        .on_window_event(|event| {
            if let tauri::WindowEvent::Destroyed = event.event() {
                // Kill the C++ server when the window closes
                // Note: on some OSes the child process might outlive if not killed explicitly
                // But generally Tauri handles cleanup, explicit kill is safer.
                if let Some(child) = event.window().state::<ServerState>()
                    .child.lock().unwrap().take() {
                    let _ = child.kill();
                }
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
