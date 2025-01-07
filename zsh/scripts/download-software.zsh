#!/usr/bin/zsh

software_table=(
    # Repo                                 # Pattern
    ventoy/Ventoy                          'ventoy-*-windows.zip'
    hellzerg/optimizer                     'Optimizer-*.exe'
    clash-verge-rev/clash-verge-rev        'Clash.Verge_*_x64-setup.exe'
    c0re100/qBittorrent-Enhanced-Edition   'qbittorrent_enhanced_*_qt6_x64_setup.exe'
    peazip/PeaZip                          'peazip-*.WIN64.exe'

    tonsky/FiraCode                        'Fira_Code_*.zip'
    microsoft/cascadia-code                'CascadiaCode-*.zip'
)

cd ~/OneDrive/Software
for repo pattern in $software_table; {
    # rm -rf $~pattern
    gh release download -R $repo -p $pattern --skip-existing
    # TODO: extract zip
}
