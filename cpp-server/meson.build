project('cpp-server', 'cpp',
  version : '0.1.0',
  default_options : [
    'cpp_std=c++17', 
    'warning_level=3',
    'werror=false'
  ])

# 1. System Threads Dependency
thread_dep = dependency('threads')

# 2. Crow: Header-only, located in third_party/
crow_inc = include_directories('third_party', is_system: true)

# 3. Asio: Detection with fallback for header-only
asio_dep = dependency('asio', required : false)

if not asio_dep.found()
  message('Asio pkg-config not found, falling back to system include search')
  cpp = meson.get_compiler('cpp')
  # Ensure the asio.hpp header actually exists on the system
  if cpp.has_header('asio.hpp')
    asio_dep = declare_dependency()
  else
    error('Asio header (asio.hpp) not found. Please install: sudo pacman -S asio')
  endif
endif

# 4. Source Files
sources = [
  'src/main.cpp'
]

# 5. Executable Definition
executable('cpp-server',
  sources,
  include_directories : crow_inc,
  dependencies : [
    thread_dep, 
    asio_dep
  ],
  install : true
)
