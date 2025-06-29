Name:           fancy-tar
Version:        1.8.3
Release:        1%{?dist}
Summary:        A modern tar wrapper with progress bars and encryption

License:        MIT
URL:            https://github.com/jgiambona/fancy-tar
Source0:        https://github.com/jgiambona/fancy-tar/archive/v%{version}.tar.gz

BuildArch:      noarch
Requires:       bash, pv

%description
fancy-tar is a Bash script that enhances the tar command by adding a progress bar and estimated time remaining.

%prep
%setup -q

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_mandir}/man1
mkdir -p %{buildroot}%{_datadir}/bash-completion/completions
mkdir -p %{buildroot}%{_datadir}/zsh/site-functions
mkdir -p %{buildroot}%{_datadir}/fish/vendor_completions.d

install -m 0755 scripts/fancy_tar_progress.sh %{buildroot}%{_bindir}/fancy-tar
install -m 0644 docs/fancy-tar.1 %{buildroot}%{_mandir}/man1/fancy-tar.1
install -m 0644 completions/fancy-tar.bash %{buildroot}%{_datadir}/bash-completion/completions/fancy-tar
install -m 0644 completions/fancy-tar.zsh %{buildroot}%{_datadir}/zsh/site-functions/_fancy-tar
install -m 0644 completions/fancy-tar.fish %{buildroot}%{_datadir}/fish/vendor_completions.d/fancy-tar.fish

%files
%{_bindir}/fancy-tar
%{_mandir}/man1/fancy-tar.1*
%{_datadir}/bash-completion/completions/fancy-tar
%{_datadir}/zsh/site-functions/_fancy-tar
%{_datadir}/fish/vendor_completions.d/fancy-tar.fish

%changelog
* Tue Mar 25 2025 Jason Giambona <jgiambona@users.noreply.github.com> - 1.6.3-1
- Added password masking for interactive password prompts
- Improved password handling with proper terminal settings restoration
- Added password strength validation in interactive mode only

* Tue Mar 25 2025 Jason Giambona <jgiambona@users.noreply.github.com> - 1.6.2-1
- Removed asciinema demos
