#!/bin/bash -e
#dnsmasq的广告屏蔽更新脚本
#国内用户需要passwall开启路由器本机代理
#by github yoier [https://github.com/yoier/r2s-firmware-build/edit/main/files/scripts/adrule.sh]

cd /tmp
wget -q https://raw.githubusercontent.com/neodevpro/neodevhost/master/dnsmasq.conf -O dnsmasq.conf.tmp0
sed -i '/^#/d' dnsmasq.conf.tmp0

wget -q -O - https://easylist-downloads.adblockplus.org/easylist.txt > dnsmasq.conf.tmp1
echo >> dnsmasq.conf.tmp1

wget -q -O - https://easylist-downloads.adblockplus.org/easylistchina.txt >> dnsmasq.conf.tmp1
echo >> dnsmasq.conf.tmp1

wget -q -O - https://easylist-downloads.adblockplus.org/easyprivacy.txt >> dnsmasq.conf.tmp1

egrep '^\|\|([a-zA-Z\.]+)\^$' dnsmasq.conf.tmp1 | cut -d '^' -f1 | sed 's#||#address=/# ; s#$#/0.0.0.0#' >> dnsmasq.conf.tmp0
sort dnsmasq.conf.tmp0 | uniq > /etc/dnsmasq.conf


#mv -f smartdns.conf /etc/smartdns/adrule.conf
/etc/init.d/dnsmasq restart
exit

