个人使用(openwrt main源码)

构建r2s-ext4极简固件

仅包含passwall2(xray，~~sing-box~~),ttyd.

其他包:python3,bash,vim-full

~~更改配置文件[network firewall dhcp](https://github.com/yoier/r2s-firmware-build/tree/main/files/etc/config)~~

~~默认旁路网关模式:192.168.27.5(主路由:192.168.27.1)~~
默认地址192.168.1.1

~~配置lan接口eth0,关闭ipv6解析~~
dnsmasq过滤广告,添加[温控脚本](https://github.com/friendlyarm/friendlywrt/tree/e1fb88ff29bcf634c875b94a9026565c7780149f/target/linux/rockchip-rk3328/base-files/usr/bin)

## Credits

- [Microsoft Azure](https://azure.microsoft.com)
- [GitHub Actions](https://github.com/features/actions)
- [OpenWrt](https://github.com/openwrt/openwrt)
- [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)
- [Mikubill/transfer](https://github.com/Mikubill/transfer)
- [softprops/action-gh-release](https://github.com/softprops/action-gh-release)
- [Mattraks/delete-workflow-runs](https://github.com/Mattraks/delete-workflow-runs)
- [dev-drprasad/delete-older-releases](https://github.com/dev-drprasad/delete-older-releases)
- [peter-evans/repository-dispatch](https://github.com/peter-evans/repository-dispatch)

## License

[MIT](https://github.com/P3TERX/Actions-OpenWrt/blob/main/LICENSE) © [**P3TERX**](https://p3terx.com)
