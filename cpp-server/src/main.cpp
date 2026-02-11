#include <chrono>
#include <cstdlib>
#include <string>
#include <print>

#include "crow_all.h"

int main(int argc, char* argv[]) {
    std::println("Lunatix C++ Server v0.1.0\n");
    int port = 8080;

    // Parse --port flag
    for (int i = 1; i < argc - 1; ++i) {
        if (std::string(argv[i]) == "--port") {
            port = std::atoi(argv[i + 1]);
        }
    }

    crow::SimpleApp app;
    auto start_time = std::chrono::steady_clock::now();

    // GET /status
    CROW_ROUTE(app, "/status")
    ([&start_time](const crow::request& /*req*/, crow::response& res) {
        // CORS headers
        res.add_header("Access-Control-Allow-Origin", "*");
        res.add_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        res.add_header("Access-Control-Allow-Headers", "Content-Type");

        auto now = std::chrono::steady_clock::now();
        auto uptime = std::chrono::duration_cast<std::chrono::seconds>(now - start_time).count();

        crow::json::wvalue body;
        body["status"] = "ok";
        body["version"] = "0.1.0";
        body["uptime_seconds"] = uptime;

        res.code = 200;
        res.set_header("Content-Type", "application/json");
        res.write(body.dump());
        res.end();
    });

    // OPTIONS preflight for any route
    CROW_ROUTE(app, "/status")
        .methods(crow::HTTPMethod::OPTIONS)([](const crow::request&, crow::response& res) {
            res.add_header("Access-Control-Allow-Origin", "*");
            res.add_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
            res.add_header("Access-Control-Allow-Headers", "Content-Type");
            res.code = 204;
            res.end();
        });

    CROW_LOG_INFO << "C++ server listening on port " << port;
    app.port(port).multithreaded().run();

    return 0;
}
