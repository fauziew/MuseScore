/*
 * SPDX-License-Identifier: GPL-3.0-only
 * MuseScore-CLA-applies
 *
 * MuseScore
 * Music Composition & Notation
 *
 * Copyright (C) 2021 MuseScore BVBA and others
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.12

import MuseScore.Ui 1.0
import MuseScore.UiComponents 1.0
import MuseScore.Instruments 1.0

Item {
    id: root

    property var instruments: null
    property var instrumentOrderTypes: null

    property bool canLiftInstrument: currentInstrumentIndex > 0
    property bool canLowerInstrument: isInstrumentSelected && (currentInstrumentIndex < instrumentsView.count - 1)

    property bool isInstrumentSelected: currentInstrumentIndex != -1
    property int currentInstrumentIndex: -1

    signal unselectInstrumentRequested(string id)
    signal orderChanged(string id)

    function scrollViewToEnd() {
        instrumentsView.positionViewAtEnd()
    }

    StyledTextLabel {
        id: instrumentsLabel

        anchors.top: parent.top
        anchors.left: parent.left

        font: ui.theme.bodyBoldFont
        text: qsTrc("instruments", "Your score")
    }

    RowLayout {
        id: operationsRow

        anchors.top: instrumentsLabel.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.right: parent.right

        StyledComboBox {
            Layout.fillWidth: true

            textRoleName: "text"
            valueRoleName: "value"

            model: {
                var resultList = []
                var orders = instrumentOrderTypes

                for (var i = 0; i < orders.length; ++i) {
                    resultList.push({"text" : qsTrc("instruments", "Order: ") + orders[i].name, "value" : orders[i].id})
                }

                return resultList
            }

            onValueChanged: {
                orderChanged(value)
            }
        }

        FlatButton {
            Layout.preferredWidth: width

            enabled: isInstrumentSelected
            text: qsTrc("instruments", "Make soloist")
        }

        FlatButton {
            Layout.preferredWidth: width

            enabled: isInstrumentSelected
            icon: IconCode.DELETE_TANK

            onClicked: {
                unselectInstrumentRequested(instruments[currentInstrumentIndex].id)
                currentInstrumentIndex--
            }
        }
    }

    ListView {
        id: instrumentsView

        anchors.top: operationsRow.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        model: instruments

        boundsBehavior: ListView.StopAtBounds
        clip: true

        ScrollBar.vertical: StyledScrollBar {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
        }

        delegate: ListItemBlank {
            isSelected: root.currentInstrumentIndex === index

            StyledTextLabel {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter

                horizontalAlignment: Text.AlignLeft
                text: modelData.name
                font: ui.theme.bodyBoldFont
            }

            onClicked: {
                root.currentInstrumentIndex = index
            }

            onDoubleClicked: {
                root.unselectInstrumentRequested(modelData.id)
            }
        }
    }

    StyledTextLabel {
        anchors.top: operationsRow.bottom
        anchors.topMargin: 20
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        visible: instrumentsView.count === 0

        text: qsTrc("instruments", "Choose your instruments by adding them to this list")
        wrapMode: Text.WordWrap
        maximumLineCount: 2
    }
}
