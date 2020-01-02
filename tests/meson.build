lib = library ('dummy', sources, asresources, config_header, dependencies: deps)
lib_dep = declare_dependency (link_with: lib)

test = executable (
    'akira_tests',
    'tests.vala',
    'test-fills-item.vala',
    dependencies: [deps, lib_dep])

test ('akiratest', test)
