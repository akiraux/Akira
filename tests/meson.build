lib = library ('dummy', sources, asresources, config_header, dependencies: deps)
lib_dep = declare_dependency (link_with: lib)

test = executable (
    'simple_unit_test',
    # 'tests.vala',
    'test-fills-item.vala',
    dependencies: [deps, lib_dep])

test ('akiratest', test)