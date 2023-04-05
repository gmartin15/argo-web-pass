#!/usr/bin/env bash
UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
VMESS_WSPATH=${VMESS_WSPATH:-'/vmess'}

sed -i "s#UUID#$UUID#g;s#VMESS_WSPATH#${VMESS_WSPATH}#g" config.json
sed -i "s#VMESS_WSPATH#${VMESS_WSPATH}#g" /etc/nginx/nginx.conf


RELEASE_RANDOMNESS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
mv xray ${RELEASE_RANDOMNESS}
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
cat config.json | base64 > config
rm -f config.json

# 启用 Argo，并输出节点日志
cloudflared tunnel --url http://localhost:80 --no-autoupdate > argo.log 2>&1 &
sleep 5 && argo_url=$(cat argo.log | grep -oE "https://.*[a-z]+cloudflare.com" | sed "s#https://##")

vmlink=$(echo -e '\x76\x6d\x65\x73\x73')://$(echo -n "{\"v\":\"2\",\"ps\":\"Argo_xray_vmess\",\"add\":\"$argo_url\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$argo_url\",\"path\":\"$VMESS_WSPATH?ed=2048\",\"tls\":\"tls\"}" | base64 -w 0)

qrencode -o /usr/share/nginx/html/M$UUID.png $vmlink

cat > /usr/share/nginx/html/$UUID.html<<-EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Argo-xray-paas</title>
    <style type="text/css">
        body {
            font-family: Geneva, Arial, Helvetica, san-serif;
        }

        div {
            margin: 0 auto;
            text-align: left;
            white-space: pre-wrap;
            word-break: break-all;
            max-width: 80%;
            margin-bottom: 10px;
        }
    </style>
</head>
<body bgcolor="#FFFFFF" text="#000000">
    <div>
        <font color="#009900"><b>VMESS协议链接：</b></font>
    </div>
    <div>$vmlink</div>
    <div>
        <font color="#009900"><b>VMESS协议二维码：</b></font>
    </div>
    <div><img src="/M$UUID.png"></div>
</body>
</html>
EOF

nginx
base64 -d config > config.json
./${RELEASE_RANDOMNESS} -config=config.json