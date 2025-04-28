#!/bin/bash
set -e

# [COMMENTS]
#
# На основе alsa-info.txt для HUAWEI HKD-WXX с кодеком Conexant CX8070:
# 0x01 - Audio Function Group (корневой узел)
# 0x10 - Audio Output для наушников (Headphone Playback Volume)
# 0x11 - Audio Output для динамиков (Speaker Playback Volume)
# 0x16 - Pin Complex для наушников (HP Out)
# 0x17 - Pin Complex для динамиков (Speaker at Int Rear)
#
# Соединения (Connection):
# - Node 0x16 подключен к 0x10* и 0x11 (звездочка означает текущее соединение)
# - Node 0x17 подключен к 0x10 и 0x11* (звездочка означает текущее соединение)
#
# EAPD состояния:
# - Node 0x16 поддерживает EAPD со значением 0x2
# - Node 0x17 поддерживает EAPD
#

# ensures script can run only once at a time
pidof -o %PPID -x $0 >/dev/null && echo "Script $0 already running" && exit 1

# Правильная команда для установки соединения - SET_CONNECT_SEL (0x301)
function set_connection() {
   hda-verb /dev/snd/hwC0D0 $1 0x301 $2 > /dev/null 2> /dev/null
}

function set_pin_widget_control() {
   hda-verb /dev/snd/hwC0D0 $1 0x707 $2 > /dev/null 2> /dev/null
}

function set_eapd_btlenable() {
   hda-verb /dev/snd/hwC0D0 $1 0x30C $2 > /dev/null 2> /dev/null
}

function switch_to_speaker() {
    # Устанавливаем соединение для динамика с выходом 0x11
    set_connection 0x17 0x1
    
    # Включаем динамик: 0x40 = OUT
    set_pin_widget_control 0x17 0x40
    
    # Включаем EAPD для динамиков (если поддерживается)
    set_eapd_btlenable 0x17 0x2
    
    # Отключаем наушники или устанавливаем минимальный режим
    set_pin_widget_control 0x16 0x0
    
    # GPIO управление через AFG для отключения наушников (если требуется)
    # Установка GPIO на основе данных из вывода AFG node 0x01
    hda-verb /dev/snd/hwC0D0 0x1 0x715 0x0 > /dev/null 2> /dev/null

    # Используем только если система использует PulseAudio
    if command -v pacmd &> /dev/null; then
        pacmd set-sink-port alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink "[Out] Speaker" 2> /dev/null || true
    fi
    
    # Если используется PipeWire вместо PulseAudio
    if command -v pw-cli &> /dev/null; then
        pw-cli set-param "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink" port "[Out] Speaker" 2> /dev/null || true
    fi
}

function switch_to_headphones() {
    # Устанавливаем соединение для наушников с выходом 0x10
    set_connection 0x16 0x0
    
    # Включаем наушники: 0xC0 = OUT HP
    set_pin_widget_control 0x16 0xC0
    
    # Включаем EAPD для наушников
    set_eapd_btlenable 0x16 0x2
    
    # Отключаем динамики
    set_pin_widget_control 0x17 0x0
    set_eapd_btlenable 0x17 0x0
    
    # GPIO управление через AFG для включения наушников
    # Установка GPIO на основе данных из вывода AFG node 0x01
    hda-verb /dev/snd/hwC0D0 0x1 0x715 0x2 > /dev/null 2> /dev/null

    # Используем только если система использует PulseAudio
    if command -v pacmd &> /dev/null; then
        pacmd set-sink-port alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink "[Out] Headphones" 2> /dev/null || true
    fi
    
    # Если используется PipeWire вместо PulseAudio
    if command -v pw-cli &> /dev/null; then
        pw-cli set-param "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink" port "[Out] Headphones" 2> /dev/null || true
    fi
}

function get_sound_card_index() {
    card_index=$(cat /proc/asound/cards | grep sof-hda-dsp | head -n1 | grep -Eo "^\s*[0-9]+")
    # remove leading white spaces
    card_index="${card_index#"${card_index%%[![:space:]]*}"}"
    echo $card_index
}

function get_jack_event(){
    card_name=$(cat /proc/asound/cards | grep -o "sof-hda-dsp" | head -n 1)
    headphone_state=$(evtest --query /dev/input/$(cat /proc/bus/input/devices | grep -A5 "${card_name} Headphone" | grep "Handlers" | awk -F= '{print $2}' | awk '{print $1}') EV_SW SW_HEADPHONE_INSERT; echo $?)
    echo $headphone_state
}

sleep 2 # allows audio system to initialise first

card_index=$(get_sound_card_index)
if [ $card_index == "" ]; then
    echo "sof-hda-dsp card is not found in /proc/asound/cards"
    exit 1
fi

old_status=0

while true; do
    # if headphone jack isn't plugged:
    if [ $(get_jack_event) -eq 0 ]; then
        status=1
    # if headphone jack is plugged:
    else
        status=2
    fi

    if [ ${status} -ne ${old_status} ]; then
        case "${status}" in
            1)
                message="Headphones disconnected"
                switch_to_speaker
                ;;
            2)
                message="Headphones connected"
                switch_to_headphones
                ;;
        esac

        echo "${message}"
        old_status=$status
    fi

    sleep .3
done
