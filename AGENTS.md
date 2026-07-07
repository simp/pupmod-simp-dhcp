# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-dhcp` is a small SIMP Puppet module that automates configuration of an
ISC DHCP **server** (`dhcpd`) on Enterprise Linux systems. It installs the DHCP
server package, manages the `/etc/dhcp/dhcpd.conf` configuration (and its
legacy `/etc/dhcpd.conf` symlink with the correct SELinux context), and runs
the `dhcpd` service. It can optionally open the BOOTP firewall port, wire up
rsyslog/logrotate for DHCP logging, and pull the `dhcpd.conf` content from an
rsync server rather than templating it locally.

The module is deliberately thin: it does not template a `dhcpd.conf` from
structured parameters. You either paste the entire config file in via the
`$dhcpd_conf` parameter, or you retrieve it from an rsync server. There is a
declared but **unimplemented** client mode.

### Business logic

- **`dhcp` (`manifests/init.pp`)** — Public selector class. Parameters
  `$is_client` (default `false`) and `$is_server` (default `true`). If
  `$is_server`, it `include`s `dhcp::dhcpd`. If `$is_client`, it only emits a
  `notify` resource stating that client mode "is not yet implemented" — there
  is no client code. Setting both is legal; server is the meaningful path.

- **`dhcp::dhcpd` (`manifests/dhcpd.pp`)** — Public class doing all real work.
  It is *not* marked `assert_private()`; it can be included directly. Key
  parameters:
  - `$package_name` (`String[1]`, no default) — supplied from module data
    (`dhcp-server` in `data/common.yaml`, overridden to `dhcp` for older OSes
    via `data/os/*.yaml`).
  - `$dhcpd_conf` (`Optional[String[1]]`, default `undef`) — the entire literal
    contents of `dhcpd.conf`. If set, it becomes the file `content` **and
    forces `$enable_data_rsync` to `false`** via the local `$_enable_data_rsync`
    variable (rsync and inline config are mutually exclusive; inline wins).
  - `$enable_data_rsync` (`Boolean`, default `true`) — the doc comment warns
    this default will be flipped to `false` in the future.
  - `$rsync_source`, `$rsync_server`, `$rsync_timeout` — rsync retrieval
    settings. `$rsync_source` defaults to a per-environment/per-OS path
    (`dhcpd_${environment}_${os.name}/dhcpd.conf`).
  - `$firewall`, `$logrotate`, `$syslog`, `$package_ensure` — SIMP feature
    toggles / package state.

  Resources it manages:
  - `package { $package_name }` at `$package_ensure`.
  - `file { '/etc/dhcp' }` directory (mode `0640`).
  - `file { '/etc/dhcp/dhcpd.conf' }` — the config file, with `content =>
    $dhcpd_conf` (nil unless supplied), SELinux `seluser => system_u`,
    `seltype => dhcp_etc_t`.
  - `file { '/etc/dhcpd.conf' }` — a `symlink` to the real file, same SELinux
    context (compatibility for tools expecting the old path).
  - `service { 'dhcpd' }` — `ensure => running`, `enable => true`, requires the
    config file and the package.
  - **Conditional** `if $firewall`: `iptables::listen::udp { 'allow_bootp' }`
    opening UDP port 67 to `trusted_nets => ['ALL']`.
  - **Conditional** `if $syslog`: `include 'rsyslog'` plus a
    `rsyslog::rule::local { 'XX_dhcpd' }` routing `dhcpd` program messages to
    `/var/log/dhcpd.log` with `stop_processing => true`. Nested inside it,
    `if $logrotate`: `include 'logrotate'` and a `logrotate::rule { 'dhcpd' }`.
    **Note the nesting: logrotate only takes effect when `$syslog` is also
    true**, because the logrotate block is inside the syslog block.
  - **Conditional** `if $_enable_data_rsync`: `include 'rsync'` plus an
    `rsync { 'dhcpd' }` resource that pulls the config to
    `/etc/dhcp/dhcpd.conf`, `subscribe`s to that file and `notify`s the
    service. The rsync `user` is `dhcpd_rsync_${environment}_${downcase os}`
    and the `password` comes from `simplib::passgen(...)` for that same name.

### Gotchas / non-obvious details

- **Client mode is a stub.** `$is_client` only produces a `notify` message; do
  not assume any client provisioning exists.
- **No template.** There is no `templates/` dir and no ERB/EPP; `dhcpd.conf`
  content is either the raw `$dhcpd_conf` string or rsync-delivered. Editing
  "the template" is not a thing here.
- **Inline config disables rsync silently.** Supplying `$dhcpd_conf` forces
  `$_enable_data_rsync = false` regardless of `$enable_data_rsync`.
- **`simp_options` is NOT a declared dependency**, but the manifests DO consume
  the `simp_options::*` seam through `simplib::lookup(...)` (provided by
  `simp/simplib`). `dhcp::dhcpd` looks up `simp_options::rsync::server`,
  `simp_options::rsync::timeout`, `simp_options::firewall`,
  `simp_options::logrotate`, `simp_options::syslog`, and
  `simp_options::package_ensure`, each with a hard-coded `default_value`. So the
  seam exists in code even though no `simp/simp_options` module is listed in
  `metadata.json`.
- **Logrotate is gated behind syslog** (see nesting above) — a common surprise.
- **SELinux contexts are hard-coded** (`system_u` / `dhcp_etc_t`); relevant only
  on SELinux-enabled EL systems.
- **rsync password derivation** uses `simplib::passgen` keyed on a computed
  name; changing the environment or OS name changes both the rsync user and its
  generated password.

## Dependencies

Module dependencies (from `metadata.json`):

- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0`
- `simp/iptables` `>= 6.5.3 < 8.0.0`
- `simp/simplib` `>= 4.9.0 < 5.0.0` (provides `simplib::lookup`, `simplib::passgen`)
- `simp/logrotate` `>= 6.5.0 < 7.0.0`
- `simp/rsyslog` `>= 7.6.0 < 9.0.0`
- `simp/rsync` `>= 6.1.1 < 7.0.0`

Fixture-only dependencies (from `.fixtures.yml`, present for test compilation
but not runtime deps): `augeas_core`, `firewalld`, `selinux_core`,
`simp_firewalld`, `systemd`.

Runtime requirement (from `metadata.json` `requirements`): `puppet
>= 7.0.0 < 9.0.0`. (SIMP is migrating Puppet → OpenVox; when
`metadata.json` switches this to `openvox`, update this line to match.)

Supported OS matrix (from `metadata.json`): Amazon 2; CentOS 8/9; RedHat 8/9;
OracleLinux 8/9; Rocky 8/9; AlmaLinux 8/9. (Some `data/os/*.yaml` files still
carry EL7-era overrides.)

## Repository layout

- `manifests/init.pp` — `dhcp` selector class (server/client toggle).
- `manifests/dhcpd.pp` — `dhcp::dhcpd`, the class that does the work.
- `data/common.yaml` — default `package_name: dhcp-server`.
- `data/os/*.yaml` — per-OS overrides (e.g. `package_name: dhcp`).
- `hiera.yaml` — module data hierarchy (v5): OS+Release, OS, Kernel, Common.
- `metadata.json` — deps, OS matrix, Puppet requirement.
- `spec/classes/{init,dhcpd}_spec.rb` — rspec-puppet unit tests.
- `spec/acceptance/suites/default/` — beaker acceptance suite; nodesets in
  `spec/acceptance/nodesets/`.
- `.fixtures.yml` — fixture module checkout list.
- `REFERENCE.md` — generated Puppet Strings reference.
- No `types/`, `lib/`, or `templates/` — this module has no custom types,
  Ruby functions/facts, or templates.
- **Acceptance runs in CI:** `.github/workflows/pr_tests.yml` has an
  `acceptance` job that runs `bundle exec rake beaker:suites[default,...]`.

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run a single spec file
bundle exec rspec spec/classes/dhcpd_spec.rb

# Puppet lint
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run the default beaker acceptance suite
bundle exec rake beaker:suites[default]
```

Relevant gem pins (from `Gemfile`): `puppetlabs_spec_helper ~> 8.0.0`,
`simp-rake-helpers ~> 5.24.0`, `simp-beaker-helpers ~> 2.0.0`. Rubocop is
pinned to `~> 1.88.0`.

## Conventions

- Preserve the `@summary` / `@param` puppet-strings docstrings on classes —
  they drive `REFERENCE.md`. Regenerate `REFERENCE.md` after changing docs or
  parameters.
- Keep `$package_name` in module data (`data/*.yaml`), not hard-coded in the
  manifest.
- Continue routing SIMP feature toggles through `simplib::lookup('simp_options::*',
  { 'default_value' => ... })` rather than assuming `simp_options` is included.
- Do not template `dhcpd.conf`; the module intentionally takes it as raw
  content or via rsync.
- The `data/common.yaml` and other baseline files carry a puppetsync notice —
  changes to baseline-managed files may be overwritten by the next sync.
- Match existing 2-space Puppet indentation and the aligned-arrow parameter
  style used in `manifests/dhcpd.pp`.
