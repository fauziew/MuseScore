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
import QtGraphicalEffects 1.0

import MuseScore.Ui 1.0
import MuseScore.UiComponents 1.0
import MuseScore.Instruments 1.0

Item {
    id: root

    property var attachedControl: undefined
    property var index: styleData.index
    property string filterKey
    property bool isSelected: false
    property bool isDragAvailable: false
    property var type: InstrumentTreeItemType.UNDEFINED

    property int keynavRow: 0
    property NavigationPanel navigationPanel: null

    property int sideMargin: 0

    signal clicked(var mouse)
    signal focusActived()

    signal popupOpened(var popupX, var popupY, var popupHeight)
    signal popupClosed()

    QtObject {
        id: prv

        property bool dragged: mouseArea.drag.active && mouseArea.pressed

        onDraggedChanged: {
            if (dragged && styleData.isExpanded) {
                attachedControl.collapse(styleData.index)
            }
        }

        property var openedPopup: null
        property bool isPopupOpened: Boolean(openedPopup) && openedPopup.isOpened

        function openPopup(popup, item) {
            if (Boolean(popup)) {
                openedPopup = popup
                popup.load(item)
                root.popupOpened(popup.x, popup.y, popup.height)
                popup.open()
            }
        }

        function closeOpenedPopup() {
            if (isPopupOpened) {
                openedPopup.close()
                resetOpenedPopup()
            }
        }

        function resetOpenedPopup() {
            root.popupClosed()
            openedPopup = null
        }
    }

    anchors {
        verticalCenter: parent ? parent.verticalCenter : undefined
        horizontalCenter: parent ? parent.horizontalCenter : undefined
    }

    height: parent ? parent.height : implicitHeight
    width: parent ? parent.width : implicitWidth

    implicitHeight: 38
    implicitWidth: 248

    Drag.keys: [ root.filterKey ]
    Drag.active: prv.dragged && isDragAvailable
    Drag.source: root
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    NavigationControl {
        id: keynavItem
        name: "ItemInstrumentsTree"
        panel: root.navigationPanel
        row: root.keynavRow
        column: 0
        enabled: visible

        onActiveChanged: {
            if (active) {
                root.focusActived()
            }
        }
    }

    Rectangle {
        id: background

        anchors.fill: parent

        color: ui.theme.backgroundPrimaryColor
        opacity: 1

        border.color: ui.theme.focusColor
        border.width: keynavItem.active ? 2 : 0

        states: [
            State {
                name: "HOVERED"
                when: mouseArea.containsMouse && !mouseArea.containsPress && !root.isSelected && !prv.dragged

                PropertyChanges {
                    target: background
                    color: ui.theme.buttonColor
                    opacity: ui.theme.buttonOpacityHover
                }
            },

            State {
                name: "PRESSED"
                when: mouseArea.containsPress && !root.isSelected && !prv.dragged

                PropertyChanges {
                    target: background
                    color: ui.theme.buttonColor
                    opacity: ui.theme.buttonOpacityHit
                }
            },

            State {
                name: "SELECTED"
                when: root.isSelected

                PropertyChanges {
                    target: background
                    color: ui.theme.accentColor
                    opacity: 0.5
                }
            },

            State {
                name: "PART_EXPANDED"
                when: styleData.isExpanded && !root.isSelected &&
                      delegateType === InstrumentTreeItemType.PART

                PropertyChanges {
                    target: background
                    color: ui.theme.textFieldColor
                    opacity: 1
                }
            },

            State {
                name: "PARENT_EXPANDED"
                when: root.visible && !root.isSelected &&
                      (delegateType === InstrumentTreeItemType.INSTRUMENT ||
                       delegateType === InstrumentTreeItemType.STAFF)

                PropertyChanges {
                    target: background
                    color: ui.theme.textFieldColor
                    opacity: 1
                }
            }
        ]
    }

    DropShadow {
        id: shadow

        anchors.fill: parent
        source: background
        color: "#75000000"
        verticalOffset: 4
        samples: 30
        visible: false
    }

    MouseArea {
        id: mouseArea

        anchors.fill: root

        propagateComposedEvents: true
        preventStealing: true

        hoverEnabled: root.visible

        drag.target: root
        drag.axis: Drag.YAxis

        onClicked: {
            keynavItem.forceActive()
            root.clicked(mouse)
        }
    }

    Loader {
        id: popupLoader
        function createPopup(comp) {
            popupLoader.sourceComponent = comp
            popupLoader.item.parent = popupLoader.parent
            return popupLoader.item
        }
    }

    Component {
        id: instrumentSettingsComp
        InstrumentSettingsPopup {
            navigation.parentControl: settingsButton.navigation
            onClosed: {
                prv.resetOpenedPopup()
                popupLoader.sourceComponent = null
            }
        }
    }

    Component {
        id: staffSettingsComp
        StaffSettingsPopup {
            navigation.parentControl: settingsButton.navigation
            onClosed: {
                prv.resetOpenedPopup()
                popupLoader.sourceComponent = null
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.sideMargin
        anchors.rightMargin: root.sideMargin

        spacing: 2

        FlatButton {
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: width

            objectName: "VisibleBtnInstrument"
            navigation.panel: root.navigationPanel
            navigation.row: root.keynavRow
            navigation.column: 1

            normalStateColor: "transparent"
            pressedStateColor: ui.theme.accentColor

            icon: model && model.itemRole.isVisible ? IconCode.VISIBILITY_ON : IconCode.VISIBILITY_OFF
            enabled: root.visible && model && model.itemRole.canChangeVisibility

            onClicked: {
                if (!model) {
                    return
                }

                model.itemRole.isVisible = !model.itemRole.isVisible
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.leftMargin: 10 * styleData.depth
            height: childrenRect.height

            FlatButton {
                id: expandButton

                anchors.left: parent.left

                objectName: "ExpandBtnInstrument"
                enabled: expandButton.visible
                navigation.panel: root.navigationPanel
                navigation.row: root.keynavRow
                navigation.column: 2

                normalStateColor: "transparent"
                pressedStateColor: ui.theme.accentColor

                icon: styleData.isExpanded ? IconCode.SMALL_ARROW_DOWN : IconCode.SMALL_ARROW_RIGHT

                visible: styleData.hasChildren && (delegateType === InstrumentTreeItemType.INSTRUMENT ? styleData.index.row === 0 : true)

                onClicked: {
                    if (!styleData.isExpanded) {
                        attachedControl.expand(styleData.index)
                    } else {
                        attachedControl.collapse(styleData.index)
                    }
                }
            }

            StyledTextLabel {
                anchors {
                    left: expandButton.right
                    leftMargin: 4
                    right: parent.right
                    rightMargin: 8
                    verticalCenter: expandButton.verticalCenter
                }
                horizontalAlignment: Text.AlignLeft

                text: model ? model.itemRole.title : ""
                opacity: model && model.itemRole.isVisible ? 1 : 0.75

                font: {
                    if (Boolean(model) && delegateType === InstrumentTreeItemType.PART && model.itemRole.isVisible) {
                        return ui.theme.bodyBoldFont
                    }

                    return ui.theme.bodyFont
                }
            }
        }

        FlatButton {
            id: settingsButton

            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: width

            objectName: "SettingsBtnInstrument"
            enabled: root.visible
            navigation.panel: root.navigationPanel
            navigation.row: root.keynavRow
            navigation.column: 3

            pressedStateColor: ui.theme.accentColor

            visible: model ? delegateType === InstrumentTreeItemType.PART ||
                             delegateType === InstrumentTreeItemType.STAFF : false

            icon: IconCode.SETTINGS_COG

            onClicked: {
                if (prv.isPopupOpened) {
                    prv.closeOpenedPopup()
                    return
                }

                var popup = null
                var item = {}

                if (root.type === InstrumentTreeItemType.PART) {

                    popup = popupLoader.createPopup(instrumentSettingsComp)

                    item["partId"] = model.itemRole.id()
                    item["partName"] = model.itemRole.title
                    item["instrumentId"] = model.itemRole.instrumentId()
                    item["instrumentName"] = model.itemRole.instrumentName()
                    item["abbreviature"] = model.itemRole.instrumentAbbreviature()

                } else if (root.type === InstrumentTreeItemType.STAFF) {

                    popup = popupLoader.createPopup(staffSettingsComp)

                    item["staffId"] = model.itemRole.id()
                    item["isSmall"] = model.itemRole.isSmall()
                    item["cutawayEnabled"] = model.itemRole.cutawayEnabled()
                    item["type"] = model.itemRole.staffType()
                    item["voicesVisibility"] = model.itemRole.voicesVisibility()
                }

                prv.openPopup(popup, item)
            }

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            opacity = 1.0
        } else {
            opacity = 0.0
        }
    }

    Behavior on opacity {
        enabled: styleData.depth !== 0
        NumberAnimation { duration: 150 }
    }

    states: [
        State {
            when: prv.dragged

            ParentChange {
                target: root
                parent: attachedControl.contentItem
            }

            PropertyChanges {
                target: shadow
                visible: true
            }

            PropertyChanges {
                target: root
                height: implicitHeight
                width: attachedControl.contentItem.width
            }

            AnchorChanges {
                target: root
                anchors {
                    verticalCenter: undefined
                    horizontalCenter: undefined
                }
            }
        }
    ]
}
