package com.freemovevr.m_ble_peripheral.model

import android.bluetooth.BluetoothGattCharacteristic

data class KGattCharacteristic(
    val entityId: String,
    val characteristic: BluetoothGattCharacteristic
)