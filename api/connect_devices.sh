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

function add_device
{
    response=$(curl -X POST -H "Content-Type: application/json" \
                 -H "Authorization: Bearer $STF_TOKEN" \
                 --data "{\"serial\": \"$DEVICE_SERIAL\"}" $STF_URL/api/v1/user/devices)

    success=$(echo "$response" | jq .success | tr -d '"')
    description=$(echo "$response" | jq .description | tr -d '"')

    if [ "$success" != "true" ]; then
        echo "Failed because $description"
        return 1
    fi

    echo "Device $DEVICE_SERIAL added successfully"
}

function remote_connect
{
    response=$(curl -X POST \
                 -H "Authorization: Bearer $STF_TOKEN" \
                $STF_URL/api/v1/user/devices/$DEVICE_SERIAL/remoteConnect)

    success=$(echo "$response" | jq .success | tr -d '"')
    description=$(echo "$response" | jq .description | tr -d '"')

    if [ "$success" != "true" ]; then
        echo "Failed because $description"
        return 1
    fi
    remote_connect_url=$(echo "$response" | jq .remoteConnectUrl | tr -d '"')

    adb connect $remote_connect_url

    echo "Device $DEVICE_SERIAL remote connected successfully"
}

isSuccess=false

while read serial
do

    DEVICE_SERIAL=$serial

    if [ "$DEVICE_SERIAL" == "" ]; then
        echo "Please set DEVICE_SERIAL"
        continue
    fi
    
    add_device || continue
    remote_connect
    if [ $? -gt 0 ]; then
        continue
    else
        isSuccess=true
    fi
done < $DEVICE_SERIALS

if ! $isSuccess ; then
    echo "There is not device to be able to test"
    exit 1
fi
