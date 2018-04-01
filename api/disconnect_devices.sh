#!/usr/bin/env bash

set -euxo pipefail

DEVICE_SERIALS="/Users/Shared/Jenkins/shell/test_devices.conf"
STF_URL="http://192.168.100.21:7100"
STF_TOKEN="77251df633a54cd0b9971922181d50035d17fd6815df4059b42b4bbc594a36f5"

if [ "$DEVICE_SERIALS" == "" ]; then
    echo "please set DEVICE_SERIALS"
    exit 1
fi

if [ "$STF_URL" == "" ]; then
    echo "please set STF_URL"
    exit 1
fi

if [ "$STF_TOKEN" == "" ]; then
    echo "please set STF_TOKEN"
    exit 1
fi

function remove_device
{
    response=$(curl -X DELETE \
                 -H "Authorization: Bearer $STF_TOKEN" \
                $STF_URL/api/v1/user/devices/$DEVICE_SERIAL)

    success=$(echo "$response" | jq .success | tr -d '"')
    description=$(echo "$response" | jq .description | tr -d '"')

    if [ "$success" != "true" ]; then
        echo "Failed because $description"
        return 1
    fi

    echo "Device $DEVICE_SERIAL removed successfully"
}

cat $DEVICE_SERIALS | while read DEVICE_SERIAL
do

    if [ "$DEVICE_SERIAL" == "" ]; then
        echo "Please set DEVICE_SERIAL"
        continue
    fi
    
    remove_device || continue

done
