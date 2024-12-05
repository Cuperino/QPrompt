/****************************************************************************
 **
 ** QPrompt
 ** Copyright (C) 2020-2024 Javier O. Cordero Pérez
 **
 ** This file is part of QPrompt.
 **
 ** This program is free software: you can redistribute it and/or modify
 ** it under the terms of the GNU General Public License as published by
 ** the Free Software Foundation, version 3 of the License.
 **
 ** This program is distributed in the hope that it will be useful,
 ** but WITHOUT ANY WARRANTY; without even the implied warranty of
 ** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ** GNU General Public License for more details.
 **
 ** You should have received a copy of the GNU General Public License
 ** along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **
 ****************************************************************************/

/****************************************************************************
 **
 ** Copyright (C) 2017, 2021 The Qt Company Ltd.
 ** Contact: https://www.qt.io/licensing/
 **
 ** This file contains code originating from examples from the Qt Toolkit.
 ** The code from the examples was licensed under the following license:
 **
 ** $QT_BEGIN_LICENSE:BSD$
 ** Commercial License Usage
 ** Licensees holding valid commercial Qt licenses may use this file in
 ** accordance with the commercial license agreement provided with the
 ** Software or, alternatively, in accordance with the terms contained in
 ** a written agreement between you and The Qt Company. For licensing terms
 ** and conditions see https://www.qt.io/terms-conditions. For further
 ** information use the contact form at https://www.qt.io/contact-us.
 **
 ** BSD License Usage
 ** Alternatively, you may use the original examples code in this file under
 ** the terms of the BSD license as follows:
 **
 ** "Redistribution and use in source and binary forms, with or without
 ** modification, are permitted provided that the following conditions are
 ** met:
 **   * Redistributions of source code must retain the above copyright
 **     notice, this list of conditions and the following disclaimer.
 **   * Redistributions in binary form must reproduce the above copyright
 **     notice, this list of conditions and the following disclaimer in
 **     the documentation and/or other materials provided with the
 **     distribution.
 **   * Neither the name of The Qt Company Ltd nor the names of its
 **     contributors may be used to endorse or promote products derived
 **     from this software without specific prior written permission.
 **
 **
 ** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 ** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 ** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 ** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 ** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 ** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 ** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 ** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 ** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 ** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 ** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
 **
 ** $QT_END_LICENSE$
 **
 ****************************************************************************/

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import QtCore 6.5
import Qt.labs.platform 1.1 as Labs

import com.cuperino.qprompt 1.0

Flickable {
    id: prompter
    // Enums
    enum States {
        Editing,
        Standby,
        Countdown,
        Prompting
    }
    enum CloseActions {
        Quit,
        LoadNew,
        LoadGuide,
        Open,
        Network,
        Ignore
    }
    enum AtEndActions {
        Stop,
        Exit,
        Loop
    }
    readonly property real editorXWidth: Math.abs(editor.x)/prompter.width
    readonly property real editorXOffset: positionHandler.x/prompter.width
    readonly property real centreX: width / 2;
    readonly property real centreY: height / 2;
    readonly property int fastSpeed: 35;
    readonly property int __jitterMargin: (__i+viewport.__baseSpeed+viewport.__curvature+fontSize)%2
    readonly property bool __possitiveDirection: __i>=0
    readonly property real __vw: width / 100 // prompter viewport width hundredth
    readonly property real __evw: editor.width / 100 // editor viewport width hundredth
    readonly property real __speed: __baseSpeed * Math.pow(Math.abs(__i), __curvature)
    readonly property real __velocity: (__possitiveDirection ? 1 : -1) * __speed
    readonly property real __relativeSpeed: (__speed * fontSize/2 * ((__vw-__evw/2) / __vw)) // Adjust relative to viewport widths and font size.
    readonly property real __travelDistance: position + topMargin - __jitterMargin
    readonly property real __timeToEnd: 2 * (editor.height + fontSize - __travelDistance) / __relativeSpeed // In seconds, used for Timer.
    readonly property real __timeToArival: __i ? ((__possitiveDirection ? __timeToEnd : 2 * __travelDistance / __relativeSpeed)) * 1000 : 0 // In milliseconds, used for animation.
    property real timeToArival: __timeToArival
    readonly property int __destination: __i  ? (__possitiveDirection ? editor.height+fontSize-__jitterMargin : __jitterMargin)-topMargin : position
    // At start and at end rules
    readonly property bool __atStart: position<=__jitterMargin-topMargin+2
    readonly property bool __atEnd: position>=editor.height-topMargin+fontSize+__jitterMargin-2
    readonly property int __speedLimit: __vw * 100
    readonly property Scale __flips: Flip{}
    // Tools to debug __atStart and __atEnd
    //readonly property bool __atStart: false
    //readonly property bool __atEnd: false
    // Patch through aliases
    property alias editor: editor
    property alias document: document
    property alias openDialog: openDialog
    property alias textColor: document.textColor
    property alias textBackground: document.textBackground
    property alias fontSize: editor.font.pixelSize
    property alias letterSpacing: editor.font.letterSpacing
    property alias wordSpacing: editor.font.wordSpacing
    // Create position alias to make code more readable
    property alias position: prompter.contentY
    property alias keys: keys
    // Flips
    property bool __flipX: false
    property bool __flipY: false
    // Scrolling settings
    property bool performFileOperations: false
    property bool winding: false
    property int atEndAction: Prompter.AtEndActions.Stop
    property int atEndLoopDelay: 3
    property int keyBeingPressed: 0
    property bool __scrollAsDial: root.__scrollAsDial
    property bool __invertArrowKeys: root.__invertArrowKeys
    property bool __invertScrollDirection: root.__invertScrollDirection
    property bool __noScroll: root.__noScroll
    property bool wysiwyg: true
    property bool __play: true
    property int __i: __iDefault
    property int __iBackup: 0
    property int __iDefault:  root.__iDefault
    property bool throttleWheel: root.__throttleWheel
    property int wheelThrottleFactor: root.__wheelThrottleFactor
    // Compute slider to decimal separately for performance improvements
    readonly property real __baseSpeed: viewport.__baseSpeed / 100
    readonly property real __curvature: viewport.__curvature / 100
    //property int __lastRecordedPosition: 0
    //property real customContentsPlacement: 0.1
    property real contentsPlacement: 0
    // Background
    property double __opacity: root.__opacity
    // Configurable keys commands
    //property var keys: {
        //"increaseVelocity": Qt.Key_Down,
        //"decreaseVelocity": Qt.Key_Up,
        //"stop": Qt.Key_Space,
        //"pause": Qt.Key_Pause,
        //"reverse": Qt.Key_R,
        //"skipBackwards": Qt.Key_PageUp,
        //"skipForward": Qt.Key_PageDown,
        //"previousMarker": Qt.Key_Home,
        //"nextMarker": Qt.Key_End,
        //"toggle": Qt.Key_F9
    //};
    Settings {
        category: "editor"
        property alias autoReload: document.autoReload
    }
    Settings {
        id: keys
        category: "keys"
        property int increaseVelocity: Qt.Key_Down
        property int increaseVelocityModifiers: Qt.platform.os==="osx" ? Qt.KeypadModifier : Qt.NoModifier
        property int decreaseVelocity: Qt.Key_Up
        property int decreaseVelocityModifiers: Qt.platform.os==="osx" ? Qt.KeypadModifier : Qt.NoModifier
        property int stop: Qt.Key_Space
        property int stopModifiers: Qt.ControlModifier
        property int pause: Qt.Key_Space
        property int pauseModifiers: Qt.NoModifier
        property int reverse: Qt.Key_I
        property int reverseModifiers: Qt.NoModifier
        property int rewind: Qt.Key_R
        property int rewindModifiers: Qt.NoModifier
        property int fastForward: Qt.Key_F
        property int fastForwardModifiers: Qt.NoModifier
        property int skipBackwards: Qt.Key_PageUp
        property int skipBackwardsModifiers: Qt.NoModifier
        property int skipForward: Qt.Key_PageDown
        property int skipForwardModifiers: Qt.NoModifier
        property int previousMarker: Qt.Key_PageUp
        property int previousMarkerModifiers: Qt.ControlModifier
        property int nextMarker: Qt.Key_PageDown
        property int nextMarkerModifiers: Qt.ControlModifier
        property int toggle: Qt.Key_F9
        property int toggleModifiers: Qt.NoModifier
        property int markerToggle: Qt.Key_M
        property int markerToggleModifiers: Qt.ControlModifier
        property int namedMarkerToggle: Qt.Key_M
        property int namedMarkerToggleModifiers: Qt.ControlModifier | Qt.ShiftModifier
        property int setVelocity0: 0
        property int setVelocity0Modifiers: Qt.NoModifier
        property int setVelocity1: Qt.Key_1
        property int setVelocity1Modifiers: Qt.NoModifier
        property int setVelocity2: Qt.Key_2
        property int setVelocity2Modifiers: Qt.NoModifier
        property int setVelocity3: Qt.Key_3
        property int setVelocity3Modifiers: Qt.NoModifier
        property int setVelocity4: Qt.Key_4
        property int setVelocity4Modifiers: Qt.NoModifier
        property int setVelocity5: Qt.Key_5
        property int setVelocity5Modifiers: Qt.NoModifier
        property int setVelocity6: Qt.Key_6
        property int setVelocity6Modifiers: Qt.NoModifier
        property int setVelocity7: Qt.Key_7
        property int setVelocity7Modifiers: Qt.NoModifier
        property int setVelocity8: Qt.Key_8
        property int setVelocity8Modifiers: Qt.NoModifier
        property int setVelocity9: Qt.Key_9
        property int setVelocity9Modifiers: Qt.NoModifier
        property int setVelocity10: Qt.Key_0
        property int setVelocity10Modifiers: Qt.NoModifier
        property int setVelocityModifier: Qt.AltModifier
    }
    Settings {
        category: "atEnd"
        property alias atEndAction: prompter.atEndAction
        property alias atEndLoopDelay: prompter.atEndLoopDelay
    }
    Settings {
        category: "prompterPlacement"
        property alias width: prompter.contentsPlacement
        property alias offset: positionHandler.placement
    }
    Settings {
        category: "files"
        property alias lastDocument: editor.lastDocument
    }

    property int q: 0
    function markerCompare() {
        // Check that state is not prompting and editor isn't active.
        if (parseInt(state)===Prompter.States.Prompting && !editor.activeFocus) {
            // Detect when moving past a marker.
            const m = document.previousMarker(editor.positionAt(0, position + overlay.__readRegionPlacement*(overlay.height-overlay.readRegionHeight)+overlay.readRegionHeight/2 + 1));
            //document.silentlySetCursorPosition(m.position);
            editor.cursorPosition = m.position;
            // Here, p is for position
            const p = editor.cursorRectangle.y;
            if (q < p) {
                console.log(m.url);
            }
            q = p;
        }
    }

    function restoreFocus() {
        prompterPage.focus = true
        if (parseInt(state)===Prompter.States.Editing)
            editor.focus = !root.__isMobile
        else
            focus = true
    }

    function cancel() {
        cursorAutoHide.reset();
        state = Prompter.States.Editing
    }

    // Toggle prompter state
    function toggle() {
        // Cancel auto loop if running
        if (loop.running)
            loop.stop()
        // Switch to next corresponding prompter state, relative to current configuration
        let nextIndex = (parseInt(state) + 1) % (Prompter.States.Prompting + 1)
        if (nextIndex===Prompter.States.Standby) {
            if (!countdown.frame)
                nextIndex = Prompter.States.Prompting
            else if (countdown.autoStart)
                nextIndex = Prompter.States.Countdown
        }
        // Skip countdown if countdown is disabled or iterations are zero
        if (nextIndex===Prompter.States.Countdown && (!countdown.enabled || countdown.__iterations===0))
            nextIndex = Prompter.States.Prompting
        state = nextIndex

        switch (parseInt(state)) {
            case Prompter.States.Editing:
                ////showPassiveNotification(i18n("Editing"), 850*countdown.__iterations)
                //// if (closeProjectionUponPromptEnd)
                ////     projectionManager.close();
                // document.preventSleep(false);
                cursorAutoHide.reset();
                break;
            case Prompter.States.Standby:
                // fall through
            case Prompter.States.Countdown:
                cursorAutoHide.reset();
            case Prompter.States.Prompting:
                // Close markers drawer unless going to Edit state
                if (markersDrawer.drawerOpen)
                    markersDrawer.close();
                timer.reset();
                if (state!==Prompter.States.Countdown)
                    document.parse();
                //if (state===Prompter.States.Prompting)
                    document.preventSleep(true);
                if (projectionManager.isEnabled)
                    projectionManager.addMissingProjections();
                //showPassiveNotification(i18n("Prompt started"), 850*countdown.__iterations)
                break;
        }
        prompter.restoreFocus()
    }

    function increaseVelocity(event) {
        event.accepted = true;
        if (this.__atEnd)
            this.__i=0
        else if (this.__velocity < this.__speedLimit) {
            if (this.__play)
                this.__i++
            this.__play = true
            this.position = this.__destination
            //if (root.passiveNotifications)
            //    showPassiveNotification(i18n("Increase Velocity"));
        }
        prompter.restoreFocus()
    }

    function decreaseVelocity(event) {
        event.accepted = true;
        if (this.__atStart)
            this.__i=0
        else if (this.__velocity > -this.__speedLimit) {
            if (this.__play)
                this.__i--
            this.__play = true
            this.position = this.__destination
            //if (root.passiveNotifications)
            //    showPassiveNotification(i18n("Decrease Velocity"));
        }
        prompter.restoreFocus()
    }

    function setVelocity(velocity: int, event: var) {
        console.log("velocity: ", velocity)
        if (this.__atStart)
            this.__i=0
        else {
            this.__i = velocity - 1
            this.position = this.__destination
            this.__i = velocity
            this.__play = true
            this.position = this.__destination
        }
        prompter.restoreFocus()
    }

    function editMarker(cursorPosition, fragmentLength) {
        goTo(cursorPosition);
        editor.select(cursorPosition, fragmentLength);
        namedMarkerConfiguration.open();
    }

    function goTo(cursorPosition) {
        const i = __i;
        __i = __iBackup
        if (parseInt(prompter.state)===Prompter.States.Prompting)
            __iBackup = 0
        // Direct placement in editor
        editor.cursorPosition = cursorPosition
        prompter.position = editor.cursorRectangle.y - (overlay.__readRegionPlacement*(overlay.height-overlay.readRegionHeight)+overlay.readRegionHeight/2) + 1
        __i = i;
        if (prompter.__play && i!==0)
            prompter.position = prompter.__destination
    }

    function goToPreviousMarker() {
        const i = __i;
        __i = __iBackup
        if (parseInt(prompter.state)===Prompter.States.Prompting)
            __iBackup = 0
        setCursorAtCurrentPosition()
        editor.cursorPosition = document.previousMarker(editor.cursorPosition).position
        prompter.position = editor.cursorRectangle.y - (overlay.__readRegionPlacement*(overlay.height-overlay.readRegionHeight)+overlay.readRegionHeight/2) + 1
        __i = i
        if (prompter.__play && i!==0)
            prompter.position = prompter.__destination
    }

    function goToNextMarker() {
        const i = __i;
        __i = __iBackup
        if (parseInt(prompter.state)===Prompter.States.Prompting)
            __iBackup = 0
        setCursorAtCurrentPosition()
        editor.cursorPosition = document.nextMarker(editor.cursorPosition).position
        prompter.position = editor.cursorRectangle.y - (overlay.__readRegionPlacement*(overlay.height-overlay.readRegionHeight)+overlay.readRegionHeight/2) + 1
        __i = i
        if (prompter.__play && i!==0)
            prompter.position = prompter.__destination
    }

    function setContentWidth() {
        //contentsPlacement = Math.abs(editor.x)/prompter.width
        contentsPlacement = Math.abs(editor.x)/(prompter.width-fontSize)
        const offset = 0
        positionHandler.placement = (2 * (editor.x - 2 * offset) + editor.width - positionHandler.width) / positionHandler.width
    }

    function ensureVisible(r)
    {
        if (parseInt(prompter.state) !== Prompter.States.Prompting) {
            if (contentX >= r.x)
                contentX = r.x;
            else if (contentX+width <= r.x+r.width)
                contentX = r.x+r.width-width;
            if (contentY >= r.y)
                contentY = r.y;
            else if (contentY+height <= r.y+r.height)
                contentY = r.y+r.height-height;
        }
    }

    function setCursorAtCurrentPosition() {
        editor.cursorPosition = editor.positionAt(0, position + overlay.__readRegionPlacement*(overlay.height-overlay.readRegionHeight)+overlay.readRegionHeight/2 + 1)
    }

    function toggleWysiwyg() {
        // Copy position value
        const lastPosition = editor.cursorPosition;

        // If leaving WYSIWYG mode or cursor is fully out of the viewport visible bounds,
        if (viewport.prompter.wysiwyg
            || lastPosition > editor.positionAt(editor.width, prompter.position+overlay.height-editor.cursorRectangle.height+editor.cursorRectangle.height)
            || lastPosition < editor.positionAt(0, prompter.position)) {
                // use reading region to place cursor.
                prompter.setCursorAtCurrentPosition();
            }
        // Else, use previous cursor position. Either way we need to get its position assigned.
        const p0_lineStart = editor.cursorPosition;
        //console.log("\n\nPos:", p0_lineStart, lastPosition, p0_lineStart<lastPosition, "\n");

        // Resize text
        viewport.prompter.wysiwyg = !viewport.prompter.wysiwyg;

        if (p0_lineStart <= lastPosition) {
            //console.log(1, "test last");
            // Set cursor at start of current line
            prompter.setCursorAtCurrentPosition();
            const p1_lineStart = editor.cursorPosition;
            //console.log(p1_lineStart);
            prompter.goTo(p0_lineStart);
            prompter.setCursorAtCurrentPosition();
            // If we're still in the same line,
            //console.log("currPos", editor.cursorPosition, editor.cursorPosition>=p1_lineStart && editor.cursorPosition<p0_lineStart?"equal":"not equal");
            if (editor.cursorPosition>=p1_lineStart && editor.cursorPosition<p0_lineStart) {
                //console.log(2, "last");
                // restore cursor position within line.
                prompter.goTo(lastPosition);
                editor.cursorPosition = lastPosition
            }
            else
                prompter.goTo(p0_lineStart);
        }
        else
            prompter.goTo(p0_lineStart);

        // Focus controls
        prompter.restoreFocus()
        // Close drawer in mobile mode
        if (typeof contextDrawer!=="undefined")
            contextDrawer.close();
    }

    contentHeight: flickableContent.height
    topMargin: overlay.__readRegionPlacement*(prompter.height-overlay.readRegionHeight)+overlay.readRegionHeight/2//+fontSize//+overlay.readRegionHeight/2//+fontSize
    bottomMargin: (1-overlay.__readRegionPlacement)*(prompter.height-overlay.readRegionHeight)+overlay.readRegionHeight

    // Clipping improves performance on large files and font sizes.
    // It also provides a workaround to the lack of background in the global toolbar when using transparent backgrounds in Material theme.
    clip: true
    transform: __flips
    layer.enabled: root.shadows
    layer.effect: ShaderEffect {
        id: shadow
        readonly property variant source: prompterShadowSource
        readonly property real angle: 180
        readonly property point offset: Qt.point(prompter.fontSize / 13 * Math.cos(angle), prompter.fontSize / 13 * Math.sin(angle))
        readonly property size delta: Qt.size(offset.x / width, offset.y / height)
        readonly property real darkness: 0.5 // + ((prompter.fontSize / (prompter.fontSize + 1)) / 2)
        readonly property ShaderEffectSource shadow: ShaderEffectSource {
            sourceItem: ShaderEffect {
                width: shadow.source.sourceItem.width
                height: shadow.source.sourceItem.height
                readonly property size delta: Qt.size(0.0, 4.0 / height)
                readonly property ShaderEffectSource source: ShaderEffectSource {
                    sourceItem: ShaderEffect {
                        width: shadow.source.sourceItem.width
                        height: shadow.source.sourceItem.height
                        readonly property size delta: Qt.size(4.0 / width, 0.0)
                        readonly property ShaderEffectSource source: shadow.source
                        fragmentShader: "/qt/qml/com/cuperino/qprompt/shaders/blur.frag.qsb"
                    }
                }
                fragmentShader: "/qt/qml/com/cuperino/qprompt/shaders/blur.frag.qsb"
            }
        }
        fragmentShader: "/qt/qml/com/cuperino/qprompt/shaders/shadow.frag.qsb"
    }

    // Flick while prompting
    onDragStarted: {
        //console.log("Drag started")
        //console.log(__iBackup, __i, position)
        if (__iBackup===0) {
            __iBackup = __i
            __i = 0
            position = position
        }
    }
    onDragEnded: {
        //console.log("Drag ended")
    }
    onFlickStarted: {
        //console.log("Flick started")
    }
    onMovementEnded: {
        //console.log("Movement ended")
        //console.log(__iBackup, __i, position)
        __i = __iBackup
        if (parseInt(prompter.state)===Prompter.States.Prompting) {
            __iBackup = 0
            position = __destination
        }
        else
           position = position
    }
    boundsBehavior: Flickable.DragOverBounds
    flickableDirection: Flickable.VerticalFlick
    //flickDeceleration: 5000
    MouseArea {
        // Enabling on Linux, Haiku OS, and macOS prevents Qt bug where wheel doesn't respond after returning to edit mode.
        // Enabling on Windows maintains behavior from 1.0, which gives consistent precission when using a mouse wheel than the behavior from Qt.
        // Disabling on macOS prevents bug where scrolling past prompter edges in edit mode resets prompter to a previous position. Choosing this approach under the presumption most Mac users will use Apple's inputs.
        enabled: Qt.platform.os!=="android" && Qt.platform.os!=="ios" && Qt.platform.os!=="osx"
        anchors.fill: parent
        scrollGestureEnabled: true
        onWheel: (wheel) => {
            mouse.scroll(wheel)
        }
    }
    //Rectangle {
    //    id: startPositionDebug
    //    visible: root.ee
    //    // Set this value to the same as __atStart's evaluated equation
    //    y: __jitterMargin-topMargin+1
    //    anchors {
    //        left: parent.left
    //        right: parent.right
    //    }
    //    height: 2
    //    color: "red"
    //}
    //Rectangle {
    //    id: endPositionDebug
    //    visible: root.ee
    //    // Set this value to the same as __atStart's evaluated equation
    //    y: editor.height-topMargin+fontSize+__jitterMargin-1
    //    anchors {
    //        left: parent.left
    //        right: parent.right
    //    }
    //    height: 2
    //    color: "red"
    //}
    Behavior on position {
        id: motion
        enabled: true
        animation: NumberAnimation {
            id: animationX
            duration: timeToArival
            easing.type: Easing.Linear
            onRunningChanged: {
                if (!animationX.running && prompter.__i && prompter.__play) {
                    __i = 0
                    root.alert(0)
                    if (parseInt(prompter.state) === Prompter.States.Prompting && !prompter.__atStart) {
                        //if (root.passiveNotifications)
                        //    showPassiveNotification(i18n("End reached"));
                        switch (prompter.atEndAction) {
                            case Prompter.AtEndActions.Exit:
                                return prompter.toggle();
                            case Prompter.AtEndActions.Loop:
                                loop.start()
                        }
                    }
                }
            }
        }
    }
    SequentialAnimation {
        id: loop
//        PropertyAction {
//            target: prompter;
//            property: "__i";
//            value: 0;
//        }
//        PropertyAction {
//            target: prompter;
//            property: "position";
//            value: position;
//        }
        onStopped: loopCountdown.resetCountdown()
        NumberAnimation {
            target: loopCountdown;
            property: "height";
            from: loopCountdown.height
            to: 0
            duration: 1000*prompter.atEndLoopDelay
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: prompter
            property: "position"
            to: __jitterMargin-topMargin+1
            duration: Units.VeryLongDuration
            easing.type: Easing.InOutQuart
        }
//        ScriptAction {
//            script: timer.reset();
//        }
//        PropertyAction {
//            target: prompter;
//            property: "state";
//            value: Prompter.States.Standby;
//        }
        // Enter edit mode
        ScriptAction {
            script: {
                loopCountdown.resetCountdown();
                prompter.cancel();
                prompter.toggle();
            }
        }
    }
    NumberAnimation on position {
        id: reset
        function toStart() {
            __i = 0
            position = position
            timer.reset()
            start()
        }
        to: __jitterMargin-topMargin+1
        duration: Units.VeryLongDuration
        easing.type: Easing.InOutQuart
    }
    Item {
        id: positionHandler
        // Force positionHandler's position to reset to center on resize.
        //x: (editor.x - (width - editor.width)/2) / 2
        property real placement: 0
        x: (editor.x - (width - editor.width + placement * width)/2) / 2

        // Keep dimensions at their right size, but adjustable
        width: parent.width
        height: editor.implicitHeight

        Item {
            id: flickableContent
            anchors.fill: parent

            TextArea {
                id: editor

                property bool resetPosition: false;
                property string lastDocument: "";

                function toggleEditorFocus(mouse) {
                    if (!editor.activeFocus) {
                        prompter.restoreFocus();
                        editor.focus = true;
                        editor.cursorPosition = editor.positionAt(mouse.x, mouse.y)
                        cursorAutoHide.reset();
                    }
                    else {
                        prompter.focus = true;
                        cursorAutoHide.restart();
                    }
                }

                //Different styles have different padding and background
                //decorations, but since this editor must resemble the
                //teleprompter output, we don't need them.
                x: contentsPlacement*(prompter.width-fontSize)

                // Width drag controls
                width: prompter.width-2*Math.abs(x)

                // Start with the editor in focus
                focus: !root.__isMobile

                textFormat: Qt.RichText
                wrapMode: TextArea.Wrap
                readOnly: false
                text: i18n("Error loading file…")

                selectByMouse: !root.__isMobile
                persistentSelection: true
                selectionColor: find.isOpen ? "#d8ecfd" : "#333d9ef3"
                selectedTextColor: find.isOpen ? "#163a58" : selectionColor
                // selectionColor: find.isOpen ? (document.regularMarker | document.namedMarker ? "#d8ecfd" : document.textColor) : "#333d9ef3"
                // selectedTextColor: find.isOpen ? (document.regularMarker | document.namedMarker ? "#163a58" : document.textBackground) : selectionColor
                leftPadding: 14
                rightPadding: 14
                topPadding: 0
                bottomPadding: 0

                onCursorRectangleChanged: prompter.ensureVisible(cursorRectangle)
                onLinkActivated: function (link) {
                    console.log(link);
                }

                background: Item {}

                font.family: westernSeriousSansfFont.name
                font.pixelSize: 14
                font.hintingPreference: Font.PreferFullHinting
                font.kerning: true
                font.preferShaping: true
                renderType: font.pixelSize < 121 || Screen.devicePixelRatio !== 1.0 || root.forceQtTextRenderer ? Text.QtRendering : Text.NativeRendering
                FontLoader {
                    id: westernSeriousSansfFont
                    source: "../fonts/DejaVuSans.ttf"
                }

                // Draggable width adjustment borders
                Component {
                    id: editorSidesBorder
                    Rectangle {
                        width: 2
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#998" }
                            GradientStop { position: 1.0; color: "#665" }
                        }
                    }
                }

                Rectangle {
                    id: rect
                    anchors.left: parent.left
                    anchors.right: parent.right
                    readonly property int m: (editor.width - prompter.width) / 2
                    anchors.leftMargin: m
                    anchors.rightMargin: m
                    anchors.top: editor.bottom
                    height: prompter.bottomMargin
                    color: "#FFF"
                    opacity: 0.15
                    Rectangle {
                        anchors.fill: parent
                        color: "#000"
                        opacity: 0.3
                    }
                }
                Item {
                    // anchors.verticalCenter: rect.verticalCenter
                    anchors.top: editor.bottom
                    anchors.left: editor.left
                    anchors.right: editor.right
                    //anchors.bottom: parent.bottom
                    height: overlay.bottomBar.height
                    opacity: parseInt(prompter.state) === Prompter.States.Prompting ? 0.3 : 0.7
                    Behavior on opacity {
                        enabled: true
                        animation: NumberAnimation {
                            duration: Units.LongDuration
                            easing.type: Easing.OutQuad
                        }
                    }
                    ColumnLayout {
                        spacing: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            FontLoader {
                                id: iconFont
                                source: "../fonts/fontello.ttf"
                            }
                            Button {
                                id: rewindButton
                                function rewind() {
                                    reset.toStart();
                                    //if (root.passiveNotifications) {
                                        //// Run hidePassiveNotification second to avoid Kirigami bug from 5.83.0 that prevents the method from completing execution.
                                        ////hidePassiveNotification()
                                        //// Scientist EE
                                        //let goToStartNotification = "";
                                        //switch (c++%3) {
                                            //case 0: goToStartNotification = i18n("Let's go back to the start"); break;
                                            //case 1: goToStartNotification = i18n("Take me back to the start"); break;
                                            //case 2: goToStartNotification = i18n("I'm going back to the start"); c=0; break;
                                        //}
                                        //showPassiveNotification(goToStartNotification);
                                    //}
                                    prompter.restoreFocus();
                                }
                                text: "\uE81A"
                                font.pixelSize: fontSize
                                font.family: iconFont.name
                                flat: true
                                opacity: parseInt(prompter.state) !== Prompter.States.Prompting || prompter.__atEnd
                                Behavior on opacity {
                                    enabled: true
                                    animation: OpacityAnimator {
                                        duration: Units.LongDuration
                                        easing.type: Easing.OutQuad
                                    }
                                }
                                //cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.passiveNotifications) {
                                        if (Qt.platform.os==="android")
                                            showPassiveNotification(i18n("Press and hold to go back to the start"));
                                        else
                                            showPassiveNotification(i18n("Double tap to go back to the start"));
                                    }
                                    prompter.focus = true
                                }
                                // Using onPressed to get an immediate response. We should to be forgiving of users who may take too long to press time based buttons
                                onPressed:
                                    if (loop.running) {
                                        loop.stop();
                                        showPassiveNotification(i18n("Auto rewind cancelled"));
                                        prompter.focus = true;
                                    }
                                onDoubleClicked:
                                    if (Qt.platform.os!=="android")
                                        rewindButton.rewind();
                                onPressAndHold:
                                    if (Qt.platform.os==="android")
                                        rewindButton.rewind();

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.topMargin: 6
                                    anchors.bottomMargin: anchors.topMargin
                                    color: "transparent"
                                    border.color: "#FFF"
                                    border.width: loopCountdown.borderWidth
                                    Rectangle {
                                        id: loopCountdown
                                        property int borderWidth: 2
                                        function resetCountdown() {
                                            height = rewindButton.height - 2 * (loopCountdown.borderWidth + parent.anchors.topMargin);
                                        }
                                        visible: rewindButton.pressed || loop.running
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.leftMargin: borderWidth
                                        anchors.rightMargin: borderWidth
                                        anchors.bottomMargin: borderWidth
                                        height: parent.height - 2*borderWidth
                                        color: "#999"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.NoButton
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }
                        RowLayout {
                            // Toggle all buttons off
                            function toggleButtonsOff() {
                                for (let i=1; i<children.length; i++)
                                    children[i].checked = false;
                            }
                            Layout.alignment: Qt.AlignCenter
                            ButtonGroup { id: atEndButtons}
                            Button {
                                text: "\uE815"
                                font.pixelSize: (fontSize < 24 ? 24 : fontSize) / 1.5
                                font.family: iconFont.name
                                flat: true
                                checkable: true
                                checked: atEndAction===Prompter.AtEndActions.Stop
                                onClicked: {
                                    if (checked) {
                                        parent.toggleButtonsOff()
                                        atEndAction=Prompter.AtEndActions.Stop
                                    }
                                    checked = true
                                }
                                onReleased: {
                                    checked = true
                                    prompter.focus = true
                                }
                                ButtonGroup.group: atEndButtons
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    cursorShape: parent.checked ? Qt.CrossCursor : Qt.PointingHandCursor
                                }
                            }
                            Button {
                                text: "\u21B6"
                                font.pixelSize: (fontSize < 24 ? 24 : fontSize) / 1.5
                                font.family: iconFont.name
                                flat: true
                                checkable: true
                                checked: atEndAction===Prompter.AtEndActions.Exit
                                onClicked: {
                                    if (checked) {
                                        parent.toggleButtonsOff()
                                        atEndAction=Prompter.AtEndActions.Exit
                                    }
                                    checked = true
                                }
                                onReleased: {
                                    checked = true
                                    prompter.focus = true
                                }
                                ButtonGroup.group: atEndButtons
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    cursorShape: parent.checked ? Qt.CrossCursor : Qt.PointingHandCursor
                                }
                            }
                            Button {
                                text: "🔁"
                                font.pixelSize: (fontSize < 24 ? 24 : fontSize) / 1.5
                                font.family: iconFont.name
                                flat: true
                                checkable: true
                                checked: atEndAction===Prompter.AtEndActions.Loop
                                onClicked: {
                                    if (checked) {
                                        parent.toggleButtonsOff()
                                        atEndAction=Prompter.AtEndActions.Loop
                                    }
                                    checked = true
                                }
                                onReleased: {
                                    checked = true
                                    prompter.focus = true
                                }
                                ButtonGroup.group: atEndButtons
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    cursorShape: parent.checked ? Qt.CrossCursor : Qt.PointingHandCursor
                                }
                            }
                        }
                        RowLayout {
                            enabled: atEndAction===Prompter.AtEndActions.Loop
                            Layout.alignment: Qt.AlignCenter
                            Button {
                                enabled: false
                                text: "\uE858"
                                font.pixelSize: (fontSize < 24 ? 24 : fontSize) / 1.75
                                font.family: iconFont.name
                                flat: true
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    cursorShape: Qt.CrossCursor
                                }
                            }
                            SpinBox {
                                value: prompter.atEndLoopDelay
                                from: 1
                                to: 60
                                font.pixelSize: (fontSize < 24 ? 24 : fontSize) / 1.75
                                onValueModified: {
                                    focus: true
                                    prompter.atEndLoopDelay = value
                                }
                                Layout.fillWidth: true
                            }
                        }
                        // RowLayout {
                        //     Layout.alignment: Qt.AlignCenter
                        //     Label {
                        //         text: i18n("The End")
                        //         font.pixelSize: (fontSize < 24 ? 24 : fontSize) / 1.5
                        //     }
                        // }
                    }
                }
                DropArea {
                    id: dragTarget
                    property alias dropProxy: dragTarget
                    property bool droppable: false
                    anchors.fill: parent
                    onPositionChanged: {
                        if (drag.hasHtml || drag.hasText)
                            dragTarget.droppable = true
                        else
                            dragTarget.droppable = false
                    }
                    onDropped: {
                        const position = editor.positionAt(drop.x, drop.y)
                        if (drop.hasHtml) {
                            const filteredHtml = document.filterHtml(drop.html, false)
                            editor.insert(position, filteredHtml)
                        }
                        else if (drop.hasText)
                            editor.insert(position, drop.text)
                    }
                    MouseArea {
                        acceptedButtons: Qt.RightButton
                        anchors.fill: parent
                        cursorShape: limitedMouse.cursorShape
                        scrollGestureEnabled: false
                        onClicked: {
                            if (!(parseInt(prompter.state) === Prompter.States.Prompting && !editor.focus)) {
                                if (root.__isMobile)
                                    contextMenu.popup(this)
                                else
                                    nativeContextMenu.open()
                            }
                        }
                    }
                    MouseArea {
                        id: limitedMouse
                        enabled: false
                        acceptedButtons: Qt.LeftButton
                        cursorShape: dragTarget.containsDrag ? (dragTarget.droppable ? Qt.DragCopyCursor : Qt.ForbiddenCursor) : Qt.IBeamCursor
                        anchors.fill: parent
                        scrollGestureEnabled: false
                        onClicked: if (editor.activeFocus) editor.cursorPosition = editor.positionAt(mouseX, mouseY);
                        onDoubleClicked: (mouse) => {
                            if (!root.__isMobile)
                                editor.toggleEditorFocus(mouse);
                        }
                    }
                }

                MouseArea {
                    id: leftWidthAdjustmentBar
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    opacity: 1
                    width: 25
                    acceptedButtons: Qt.LeftButton
                    scrollGestureEnabled: false
                    propagateComposedEvents: true
                    hoverEnabled: false
                    cursorShape: prompter.dragging ? Qt.ClosedHandCursor : ((pressed || drag.active) ? (forcedOrientation && forcedOrientation!==3 ? Qt.SplitVCursor : Qt.SplitHCursor) : (flicking ? Qt.OpenHandCursor : (forcedOrientation && forcedOrientation!==3 ? Qt.SizeVerCursor : Qt.SizeHorCursor)))
                    anchors.left: Qt.application.layoutDirection===Qt.LeftToRight ? editor.left : undefined
                    anchors.right: Qt.application.layoutDirection===Qt.RightToLeft ? editor.right : undefined
                    drag.target: editor
                    drag.axis: Drag.XAxis
                    drag.smoothed: false
                    drag.minimumX: 0 // fontSize/2 //: -prompter.width*6/20 + width
                    drag.maximumX: prompter.width*9/20 //: -fontSize/2 + width
                    onReleased: prompter.setContentWidth()
                    //onClicked: (mouse) => {
                    //    mouse.accepted = false
                    //}
                    Loader {
                        sourceComponent: editorSidesBorder
                        anchors {top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter}
                    }
                }
                MouseArea {
                    id: rightWidthAdjustmentBar
                    opacity: editor.x === leftWidthAdjustmentBar.drag.minimumX ? 0.6 : 1
                    scrollGestureEnabled: false
                    acceptedButtons: Qt.LeftButton
                    propagateComposedEvents: true
                    hoverEnabled: false
                    x: parent.width-width
                    width: 25
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    drag.target: positionHandler
                    drag.axis: Drag.XAxis
                    drag.smoothed: false
                    drag.minimumX: -editor.x // + fontSize/2 //prompter.width - editor.x - editor.width - leftWidthAdjustmentBar.drag.maximumX
                    drag.maximumX: prompter.width - editor.x - parent.width - leftWidthAdjustmentBar.drag.minimumX
                    cursorShape: (pressed||drag.active||prompter.dragging) ? Qt.ClosedHandCursor : flicking ? Qt.OpenHandCursor : (contentsPlacement ? Qt.OpenHandCursor : Qt.ArrowCursor)
                    Loader {
                        sourceComponent: editorSidesBorder
                        anchors {top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter}
                    }
                    //onPressed: editor.invertDrag = true
                    onReleased: positionHandler.placement = (2 * (editor.x - 2 * positionHandler.x) + editor.width - positionHandler.width) / positionHandler.width
                }

                Keys.onPressed: function(event) {
                    // Prompter related keys are processed first for faster response times.
                    // Assumption: Editor is focused.
                    if (parseInt(prompter.state) === Prompter.States.Prompting) {
                        // Assumption: We're in edit while prompting mode.
                        // If moving cursor would place it out of bounds that are practical for editing, prevent motion and prevent event from floating up to prompter, which would trigger a change in velocity.
                        if (event.key === Qt.Key_Right && editor.cursorPosition > editor.positionAt(editor.width, prompter.position+overlay.height) - 1
                            || event.key === Qt.Key_Left && editor.cursorPosition < editor.positionAt(0, prompter.position) + 1
                            || event.key === Qt.Key_Down && editor.cursorPosition > editor.positionAt(editor.width, prompter.position+overlay.height-editor.cursorRectangle.height-editor.cursorRectangle.height/4)
                            || event.key === Qt.Key_Up && editor.cursorPosition < editor.positionAt(0, prompter.position+1.5*editor.cursorRectangle.height)) {
                            event.accepted = true;
                            return;
                        }
                        // Prevent programmable keys from typing on editor while prompting
                        switch (event.key) {
                            case keys.increaseVelocity:
                            case keys.decreaseVelocity:
                            case keys.stop:
                            case keys.pause:
                            case keys.reverse:
                            case keys.rewind:
                            case keys.fastForward:
                            case keys.skipBackwards:
                            case keys.skipForward:
                            case keys.previousMarker:
                            case keys.nextMarker:
                            case keys.markerToggle:
                            case keys.namedMarkerToggle:
                            case keys.setVelocity0:
                            case keys.setVelocity1:
                            case keys.setVelocity2:
                            case keys.setVelocity3:
                            case keys.setVelocity4:
                            case keys.setVelocity5:
                            case keys.setVelocity6:
                            case keys.setVelocity7:
                            case keys.setVelocity8:
                            case keys.setVelocity9:
                            case keys.setVelocity10:
                            case keys.toggle:
                                // If in edit while prompting mode, ensure arrow keys and space bar don't float up to prompter so editor can make proper use of them.
                                if ((Qt.Key_Left <= event.key && event.key <= Qt.Key_Down) || (Qt.Key_Space <= event.key && event.key <= Qt.Key_Dead_Longsolidusoverlay)) {
                                    event.accepted = false;
                                    return;
                                }
                                // All other actions should float to prompter, preventing the editor from making use of these keys.
                                event.accepted = true;
                                prompter.Keys.onPressed(event);
                                return;
                        }
                    }
                    // In all modes, editor should...
                    if (event.modifiers & Qt.ControlModifier)
                        switch (event.key) {
                            case Qt.Key_B:
                                document.bold = !document.bold;
                                return;
                            case Qt.Key_U:
                                document.underline = !document.underline;
                                return;
                            case Qt.Key_I:
                                document.italic = !document.italic;
                                return;
                            case Qt.Key_T:
                                document.strike = !document.strike;
                                return;
                            case Qt.Key_L:
                                document.alignment = Qt.AlignLeft;
                                return;
                            case Qt.Key_R:
                                document.alignment = Qt.AlignRight;
                                return;
                            case Qt.Key_E:
                                document.alignment = Qt.AlignCenter;
                                return;
                            // Justify is proven to make text harder to read for some readers. So I'm commenting out all text justification options from the program. I'm not removing them, only commenting out in case someone needs to re-enable. This article links to various sources that validate my decision: https://kaiweber.wordpress.com/2010/05/31/ragged-right-or-justified-alignment/ - Javier
                            //case Qt.Key_J:
                            //    document.alignment = Qt.AlignJustify;
                            //    return;
                            case Qt.Key_M:
                                if (event.modifiers & Qt.ShiftModifier)
                                    namedMarkerConfiguration.open();
                                else
                                    document.regularMarker = !document.regularMarker;
                                return;
                            // Forward these other keys to prompter.
                            case Qt.Key_F:
                            case Qt.Key_V:
                                prompter.Keys.onPressed(event);
                                return;
                        }
                    // If no modifiers are pressed...
                    else
                        switch (event.key) {
                            // Forward these other keys to prompter.
                            case Qt.Key_V:
                                prompter.Keys.onPressed(event);
                                return;
                            // Change item in focus when Tab is pressed. This is an accessibility feature.
                            case Qt.Key_Tab:
                                event.accepted = true;
                                editor.nextItemInFocusChain().forceActiveFocus();
                                return;
                        }
                }
            }
        }
    }

    DocumentHandler {
        id: document

        property bool isNewFile: false
        property bool quitOnSave: false

        function resetDocumentPosition() {
            if (editor.resetPosition) {
                prompter.position = -(overlay.__readRegionPlacement*(overlay.height-overlay.readRegionHeight)+overlay.readRegionHeight/2)
                editor.resetPosition = false;
            }
        }
        function clearLastDocument() {
            editor.lastDocument = "blank://";
        }
        function close() {
            networkDialog.autoReloadRunning = false;
            document.load("qrc:/qt/qml/com/cuperino/qprompt/documents/blank.html");
        }
        function newDocument() {
            root.onDiscard = Prompter.CloseActions.LoadNew
            if (document.modified)
                closeDialog.open()
            else {
                document.close()
                document.load("qrc:/qt/qml/com/cuperino/qprompt/documents/untitled.html")
                clearLastDocument();
                isNewFile = true
                resetDocumentPosition()
                if (root.passiveNotifications)
                    showPassiveNotification(i18n("New document"))
            }
        }
        function loadGuide() {
            root.onDiscard = Prompter.CloseActions.LoadGuide
            if (document.modified)
                closeDialog.open()
            else {
                document.close()
                document.load("qrc:/qt/qml/com/cuperino/qprompt/documents/"+i18n("welcome_en.html"))
                editor.lastDocument = ""
                isNewFile = true
                prompter.position = 0
                if (root.passiveNotifications)
                    showPassiveNotification(i18n("User welcome loaded"))
            }
        }
        function loadLastDocument() {
            root.onDiscard = Prompter.CloseActions.Open
            document.close()
            document.load(editor.lastDocument)
            isNewFile = false
            prompter.position = 0
            if (root.passiveNotifications)
                showPassiveNotification(i18n("Loaded: %1", editor.lastDocument))
        }
        function open() {
            root.onDiscard = Prompter.CloseActions.Open
            if (document.modified)
                closeDialog.open()
            else
                openDialog.open()
        }
        function openFromNetwork() {
            root.onDiscard = Prompter.CloseActions.Network
            if (document.modified)
                closeDialog.open()
            else
                networkDialog.open()
        }
        function saveAsDialog() {
            saveDialog.open(parseInt(root.onDiscard)===Prompter.CloseActions.Quit)
        }
        function saveDialog(quit=false) {
            //document.quitOnSave = quit
            if (document.modified) {
                if (isNewFile)
                    saveAsDialog()
                else {
                    document.modified = false
                    if (Qt.platform.os==="android" || Qt.platform.os==="ios" || visibility===ApplicationWindow.FullScreen) {
                        if (document.isNewFile)
                            showPassiveNotification(i18nc("Saved FILE_NAME", "Saved %1", document.file))
                        else
                            showPassiveNotification(i18n("Saved"))
                    }
                    document.saveAs(document.fileUrl)
                    //if (quit)
                        //Qt.quit()
                    //else
                    switch (parseInt(root.onDiscard)) {
                        case Prompter.CloseActions.LoadGuide: document.loadGuide(); break;
                        case Prompter.CloseActions.LoadNew: document.newDocument(); break;
                        case Prompter.CloseActions.Open: document.open(); break;
                        case Prompter.CloseActions.Network: document.openFromNetwork(); break;
                        case Prompter.CloseActions.Quit: Qt.quit()
                    }
                }
            }
        }

        document: editor.textDocument
        cursorPosition: editor.cursorPosition
        selectionStart: editor.selectionStart
        selectionEnd: editor.selectionEnd
        //textColor: "#FFF"
        //textBackground: "#000"

        onLoaded: function (format) {
            editor.textFormat = format
            editorToolbar.lineHeightSlider.update()
            editorToolbar.paragraphSpacingSlider.update()
        }
        onError: function (message) {
            errorDialog.text = message
            errorDialog.visible = true
        }

        Component.onCompleted: {
            if (prompter.performFileOperations) {
                if (typeof fileToOpen!=="undefined") {
                    document.load("file:" + fileToOpen);
                    isNewFile = false
                }
                else if (editor.lastDocument === "")
                    loadGuide();
                else if (editor.lastDocument === "blank://")
                    newDocument();
                else
                    document.loadLastDocument();
            }
        }
    }

    // Progress indicator
    ScrollBar.vertical: ProgressIndicator {
        id: scrollBar
    }

    Labs.FileDialog {
        id: openDialog
        nameFilters:
            ['android', 'ios', 'tvos', 'wasm'].indexOf(Qt.platform.os)===-1 ?
            [
                i18nc("Format name (FORMAT_EXTENSION)", "Hypertext Markup Language (%1)", "HTML") + "(*.html *.htm *.xhtml *.HTML *.HTM *.XHTML)",
                i18nc("Format name (FORMAT_EXTENSION)", "Markdown (%1)", "MD") + "(*.md *.MD)",
                i18nc("Format name (FORMAT_EXTENSION)", "Plain Text (%1)", "TXT") + "(*.txt *.text *.TXT *.TEXT)",
                i18nc("Format name (FORMAT_EXTENSION)", "OpenDocument Format Text Document (%1)", "ODT") + "(*.odt *.ODT)",
                i18nc("Format name (FORMAT_EXTENSION)", "AbiWord Document (%1)", "ABW") + "(*.abw *.ABW *.zabw *.ZABW)",
                i18nc("Format name (FORMAT_EXTENSION)", "Microsoft Word document (%1)", "DOCX, DOC") + "(*.docx *.doc *.DOCX *.DOC)",
                i18nc("Format name (FORMAT_EXTENSION)", "Apple Pages Document (%1)", "PAGES") + "(*.pages *.PAGES)",
                i18nc("Format name (FORMAT_EXTENSION)", "Rich Text Format (%1)", "RTF") + "(*.rtf *.RTF)",
                //i18nc("Format name (FORMAT_EXTENSION)", "Portable Document Format (%1)", "PDF") + "(*.pdf *.PDF)",
                i18nc("All file formats", "All Formats") + "(*.*)"
            ]
          : [ // Remove options that rely on external tools in mobile and embedded platforms
                i18nc("Format name (FORMAT_EXTENSION)", "Hypertext Markup Language (%1)", "HTML") + "(*.html *.htm *.xhtml *.HTML *.HTM *.XHTML)",
                i18nc("Format name (FORMAT_EXTENSION)", "Markdown (%1)", "MD") + "(*.md *.MD)",
                i18nc("Format name (FORMAT_EXTENSION)", "Plain Text (%1)", "TXT") + "(*.txt *.text *.TXT *.TEXT)",
                //i18nc("Format name (FORMAT_EXTENSION)", "Rich Text Format (%1)", "RTF") + "(*.rtf *.RTF)",
                //i18nc("Format name (FORMAT_EXTENSION)", "Portable Document Format (%1)", "PDF") + "(*.pdf *.PDF)",
                i18nc("All file formats", "All Formats") + "(*.*)"
            ]
        selectedNameFilter.index: 0

        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        fileMode: Labs.FileDialog.OpenFile
        onAccepted: {
            document.close()
            document.load(openDialog.file)
            editor.lastDocument = document.fileUrl;
            editor.resetPosition = true;
            if (parseInt(prompter.state)!==Prompter.States.Editing)
                prompter.state = Prompter.States.Editing;
            document.isNewFile = !(selectedNameFilter.index===0 || Qt.platform.os!=="android" && selectedNameFilter.index===2)
        }
    }

    Labs.FileDialog {
        id: saveDialog
        defaultSuffix: 'html'
        nameFilters: if (Qt.platform.os==="android")
            return [
                i18nc("Format name (FORMAT_EXTENSION)", "Hypertext Markup Language (%1)", "HTML") + "(*.html *.htm *.xhtml *.HTML *.HTM *.XHTML)"
            ]
        else
            return [
                i18nc("Format name (FORMAT_EXTENSION)", "Hypertext Markup Language (%1)", "HTML") + "(*.html *.htm *.xhtml *.HTML *.HTM *.XHTML)",
                i18nc("Format name (FORMAT_EXTENSION)", "Plain Text (%1)", "TXT") + "(*.txt *.text *.TXT *.TEXT)"
                //i18nc("All file formats", "All Formats") + "(*.*)"
            ]
        //// Always in the same format as original file
        //selectedNameFilter.index: document.fileType === "txt" ? 0 : 1
        // Always save as HTML
        //selectedNameFilter: nameFilters[0]
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        fileMode: Labs.FileDialog.SaveFile
        onAccepted: {
            document.saveAs(saveDialog.file)
            document.isNewFile = false
            editor.lastDocument = document.fileUrl;
            showPassiveNotification(i18nc("Saved FILE_NAME", "Saved %1", document.file))
            // if (document.quitOnSave)
            //     Qt.quit()
            // else
            //console.log("onDiscard:", root.onDiscard)
            switch (parseInt(root.onDiscard)) {
                case Prompter.CloseActions.LoadGuide: document.modified = false; document.loadGuide(); break;
                case Prompter.CloseActions.LoadNew: document.modified = false; document.newDocument(); break;
                case Prompter.CloseActions.Open: document.open(); /*openOpenDialog.start();*/ break;
                case Prompter.CloseActions.Network: document.modified = false; document.openFromNetwork(); break;
                case Prompter.CloseActions.Quit: Qt.quit()
                //default: Qt.quit();
            }
        }
    }

    Labs.MessageDialog {
        id: errorDialog
        modality: Qt.WindowModal
    }

    // Context Menu
    Labs.Menu {
        id: nativeContextMenu
        Labs.MenuItem {
            text: i18nc("Global menu and editor context menu actions", "&Copy")
            enabled: editor.selectedText
            onTriggered: editor.copy()
        }
        Labs.MenuItem {
            text: i18nc("Global menu and editor context menu actions", "Cu&t")
            enabled: editor.selectedText
            onTriggered: editor.cut()
        }
        Labs.MenuItem {
            text: i18nc("Global menu and editor context menu actions", "&Paste")
            enabled: editor.canPaste
            onTriggered: document.paste()
        }
        Labs.MenuSeparator {}
        Labs.MenuItem {
            text: i18nc("Editor context menu actions", "Fo&nt…")
            onTriggered: document.showFontDialog()
        }
        Labs.MenuItem {
            text: i18nc("Editor context menu actions", "Co&lor…")
            onTriggered: colorDialog.open()
        }
        Labs.MenuItem {
            text: i18nc("Editor context menu actions", "Hi&ghlight…")
            onTriggered: highlightDialog.open()
        }
    }
    Menu {
        id: contextMenu
        background: Rectangle {
            color: "#DD000000"
            implicitWidth: 120
            //implicitHeight: 30
        }
        MenuItem {
            text: i18nc("Editor context menu actions", "&Undo")
            enabled: prompter.editor.canUndo
            onTriggered: prompter.editor.undo()
        }
        MenuItem {
            text: i18nc("Editor context menu actions", "Redo")
            enabled: prompter.editor.canRedo
            onTriggered: prompter.editor.redo()
        }
        MenuSeparator {}
        MenuItem {
            text: i18nc("Global menu and editor context menu actions", "&Copy")
            enabled: editor.selectedText
            onTriggered: editor.copy()
        }
        MenuItem {
            text: i18nc("Global menu and editor context menu actions", "Cu&t")
            enabled: editor.selectedText
            onTriggered: editor.cut()
        }
        MenuItem {
            text: i18nc("Global menu and editor context menu actions", "&Paste")
            enabled: editor.canPaste
            onTriggered: document.paste()
        }
        MenuSeparator {}
        MenuItem {
            text: i18nc("Editor context menu actions", "Fo&nt…")
            onTriggered: document.showFontDialog()
        }
        MenuItem {
            text: i18nc("Editor context menu actions", "Co&lor…")
            onTriggered: colorDialog.open()
        }
        MenuItem {
            text: i18nc("Editor context menu actions", "Hi&ghlight…")
            onTriggered: highlightDialog.open()
        }
        MenuSeparator {}
    }

    Settings {
        category: "flip"
        property alias x: prompter.__flipX
        property alias y: prompter.__flipY
    }

    // Key bindings
    Keys.onPressed: function(event) {
        if (parseInt(prompter.state)===Prompter.States.Prompting) {
            if (event.key===keys.increaseVelocity && event.modifiers===keys.increaseVelocityModifiers || event.key===Qt.Key_VolumeDowm) {
                // Increase Velocity
                if (prompter.__invertArrowKeys)
                    prompter.decreaseVelocity(event)
                else
                    prompter.increaseVelocity(event)
                return
            }
            else if (event.key===keys.decreaseVelocity && event.modifiers===keys.decreaseVelocityModifiers || event.key===Qt.Key_VolumeUp) {
                // Decrease Velocity
                if (prompter.__invertArrowKeys)
                    prompter.increaseVelocity(event)
                else
                    prompter.decreaseVelocity(event)
                return
            }
            else if (event.key===keys.stop && event.modifiers===keys.stopModifiers) {
                // Stop
                prompter.__i = 0;
                prompter.__iBackup = 0;
                prompter.position = prompter.position
                return
            }
            else if (event.key===keys.pause && event.modifiers===keys.pauseModifiers || event.key===Qt.Key_SysReq || event.key===Qt.Key_Play || event.key===Qt.Key_Pause) {
                // Pause
                //if (root.passiveNotifications)
                //    showPassiveNotification((i18n("Toggle Playback"));
                if (prompter.__play) {
                    prompter.__play = false
                    prompter.position = prompter.position
                }
                else {
                    prompter.__play = true
                    prompter.position = prompter.__destination
                }
                return
            }
            else if (event.key===keys.setVelocity0 && (event.modifiers===keys.setVelocity0Modifiers ||
                                                       event.modifiers===(keys.setVelocity0Modifiers ^ keys.setVelocityModifier))) {
                setVelocity(0, event);
                return;
            }
            else if (event.key===keys.setVelocity1 && event.modifiers===keys.setVelocity1Modifiers) {
                setVelocity(1, event);
                return;
            }
            else if (event.key===keys.setVelocity1 && event.modifiers===(keys.setVelocity1Modifiers ^ keys.setVelocityModifier)) {
                setVelocity(-1, event);
                return;
            }
            else if (event.key===keys.setVelocity2 && event.modifiers===keys.setVelocity2Modifiers) {
                setVelocity(2, event);
                return;
            }
            else if (event.key===keys.setVelocity2 && event.modifiers===(keys.setVelocity2Modifiers ^ keys.setVelocityModifier)) {
                setVelocity(-2, event);
                return;
            }
            else if (event.key===keys.setVelocity3 && event.modifiers===(keys.setVelocity3Modifiers)) {
                setVelocity(3, event);
                return;
            }
            else if (event.key===keys.setVelocity3 && event.modifiers===(keys.setVelocity3Modifiers ^ keys.setVelocityModifier)) {
                setVelocity(-3, event);
                return;
            }
            else if (event.key===keys.setVelocity4 && event.modifiers===keys.setVelocity4Modifiers) {
                setVelocity(4, event);
                return;
            }
            else if (event.key===keys.setVelocity4 && event.modifiers===(keys.setVelocity4Modifiers ^ keys.setVelocityModifier)) {
                setVelocity(-4, event);
                return;
            }
            else if (event.key===keys.setVelocity5 && event.modifiers===keys.setVelocity5Modifiers) {
                setVelocity(5, event);
                return;
            }
            else if (event.key===keys.setVelocity5 && event.modifiers===(keys.setVelocity5Modifiers ^ keys.setVelocityModifier)) {
                setVelocity(-5, event);
                return;
            }
            else if (event.key===keys.setVelocity6 && event.modifiers===keys.setVelocity6Modifiers) {
                setVelocity(6, event);
                return;
            }
            else if (event.key===keys.setVelocity6 && event.modifiers===(keys.setVelocity6Modifiers ^ keys.setVelocityModifier)) {
                setVelocity(-6, event);
                return;
            }
            else if (event.key===keys.setVelocity7 && event.modifiers===keys.setVelocity7Modifiers) {
                setVelocity(7, event);
                return;
            }
            else if (event.key===keys.setVelocity7 && event.modifiers===(keys.setVelocity7Modifiers ^ keys.setVelocityModifier)) {
                setVelocity(-7, event);
                return;
            }
            else if (event.key===keys.setVelocity8 && event.modifiers===keys.setVelocity8Modifiers) {
                setVelocity(8, event);
                return;
            }
            else if (event.key===keys.setVelocity8 && event.modifiers===(keys.setVelocity8Modifiers ^ keys.setVelocityModifier)) {
                setVelocity(-8, event);
                return;
            }
            else if (event.key===keys.setVelocity9 && event.modifiers===keys.setVelocity9Modifiers) {
                setVelocity(9, event);
                return;
            }
            else if (event.key===keys.setVelocity9 && event.modifiers===(keys.setVelocity9Modifiers ^ keys.setVelocityModifier)) {
                setVelocity(-9, event);
                return;
            }
            else if (event.key===keys.setVelocity10 && event.modifiers===keys.setVelocity10Modifiers) {
                setVelocity(10, event);
                return;
            }
            else if (event.key===keys.setVelocity10 && event.modifiers===(keys.setVelocity10Modifiers ^ keys.setVelocityModifier)) {
                setVelocity(-10, event);
                return;
            }
            else if (event.key===keys.reverse && event.modifiers===keys.reverseModifiers) {
                // Reverse
                __i = -__i;
                position = __destination
                return
            }
            else if (event.key===keys.rewind && event.modifiers===keys.rewindModifiers) {
                // Rewind
                if (!winding) {
                    __iBackup = __i;
                    winding = true;
                    keyBeingPressed = event.key;
                    __i = 0;
                    position = __destination
                    __i = -fastSpeed;
                    position = __destination
                }
                return
            }
            else if (event.key===keys.fastForward && event.modifiers===keys.fastForwardModifiers) {
                // Fast Forward
                if (!winding) {
                    __iBackup = __i;
                    winding = true;
                    keyBeingPressed = event.key;
                    __i = 0;
                    position = __destination
                    __i = fastSpeed;
                    position = __destination
                }
                return
            }
            // else {
            //     Show key code
            //     showPassiveNotification(event.key)
            // }

            // Perform keyCode marker search.
            let namedAnchorPosition = document.keySearch(event.key);
            if (namedAnchorPosition!==-1)
                prompter.goTo(namedAnchorPosition);
            //// Undo and redo key bindings
            //if (event.matches(StandardKey.Undo))
            //    document.undo();
            //else if (event.matches(StandardKey.Redo))
            //    document.redo();
        }

        // Key press that apply states other than Editing or Prompting.
        // Pause and stop toggle prompter state.
        else if (parseInt(prompter.state)!==Prompter.States.Editing && event.key===keys.stop && event.modifiers===keys.stopModifiers || parseInt(prompter.state)!==Prompter.States.Editing && event.key===keys.pause && event.modifiers===keys.pauseModifiers || event.key===Qt.Key_SysReq || event.key===Qt.Key_Play || event.key===Qt.Key_Pause)
            prompter.toggle();

        // Keys presses that apply the same to all states, including previous
        if (event.key===Qt.Key_F && event.modifiers & Qt.ControlModifier)
            find.open();
        else if (event.key===Qt.Key_V && event.modifiers & Qt.ControlModifier) {
            event.accepted = true
            if (event.modifiers & Qt.ShiftModifier)
                document.paste(true);
            else
                document.paste();
        }
        if (event.key===Qt.Key_D && event.modifiers & Qt.ControlModifier)
            editor.cursorPosition = editor.selectionStart;
        else if (event.key===keys.toggle && event.modifiers===keys.toggleModifiers)
            // Toggle state
            prompter.toggle();
        else if (event.key===keys.skipBackwards && event.modifiers===keys.skipBackwardsModifiers) {
            // Move back
            /* if (event.modifiers & Qt.ControlModifier)
                prompter.goToPreviousMarker();
            else */
            if (!this.__atStart) {
                if (prompter.__play && __i!==0)
                    __iBackup = __i
                __i=0;
                prompter.position = prompter.position
                scrollBar.decrease()
                __i=__iBackup
                if (prompter.__play)
                    prompter.position = __destination
                else
                    prompter.position = prompter.position
            }
        }
        else if (event.key===keys.skipForward && event.modifiers===keys.skipForwardModifiers) {
            // Move Forward
            /* if (event.modifiers & Qt.ControlModifier)
                prompter.goToNextMarker();
            else */
            if (!this.__atEnd) {
                if (prompter.__play && __i!==0)
                    __iBackup = __i
                __i=0;
                prompter.position = prompter.position
                scrollBar.increase()
                __i=__iBackup
                if (prompter.__play)
                    prompter.position = __destination
                else
                    prompter.position = prompter.position
            }
        }
        else if (event.key===keys.previousMarker && event.modifiers===keys.previousMarkerModifiers)
            prompter.goToPreviousMarker();
        // Go to next marker
        else if (event.key===keys.nextMarker && event.modifiers===keys.nextMarkerModifiers)
            prompter.goToNextMarker();
        return
    }
    Keys.onReleased: function(event) {
        if (parseInt(prompter.state)===Prompter.States.Prompting) {
            if (winding && (event.key===keyBeingPressed && (event.key===keys.rewind || event.key===keys.fastForward))) {
                // Let go
                __i = 0;
                position = __destination
                __i = __iBackup;
                position = __destination
                winding = false;
            }
            return
        }
    }

    states: [
        State {
            name: Prompter.States.Editing
            //PropertyChanges {
            //target: readRegion
            //__placement: readRegion.__placement
            //}
            //PropertyChanges {
            //target: readRegionButton
            //text: i18n("Custom")
            //icon.name: "dialog-ok-apply"
            //}
            PropertyChanges {
                target: overlay
                state: ReadRegionOverlay.States.NotPrompting
            }
            PropertyChanges {
                target: countdown
                state: Countdown.States.Standby
            }
            PropertyChanges {
                target: editor
                focus: !root.__isMobile
                selectByMouse: !root.__isMobile
                activeFocusOnPress: true
                //cursorPosition: editor.positionAt(0, editor.position + 1*overlay.height/2)
            }
            PropertyChanges {
                target: promptingButton
                icon.source: Qt.application.layoutDirection === Qt.RightToLeft ?
                                 "../icons/go-previous.svg" : "../icons/go-next.svg"
            }
            PropertyChanges {
                target: prompter
                z: 2
                __i: 0
                __play: false
                position: position
                timeToArival: 0
            }
            PropertyChanges {
                target: viewport.mouse
                z: 0
            }
        },
        State {
            name: Prompter.States.Standby
            PropertyChanges {
                target: overlay
                state: ReadRegionOverlay.States.Prompting
            }
            PropertyChanges {
                target: countdown
                state: Countdown.States.Ready
            }
            PropertyChanges {
                target: timer
                elapsedMilliseconds: 0
            }
            PropertyChanges {
                target: promptingButton
                text: viewport.countdown.enabled ? i18n("Begin countdown") : i18n("Start prompting")
                icon.source: Qt.application.layoutDirection === Qt.RightToLeft ?
                                 "../icons/go-previous.svg" : "../icons/go-next.svg"
            }
            PropertyChanges {
                target: prompter
                z: 1
                __iBackup: 0
                position: position
                timeToArival: 0
                focus: true
            }
            PropertyChanges {
                target: editor
                selectByMouse: false
                activeFocusOnPress: true
            }
            PropertyChanges {
                target: leftWidthAdjustmentBar
                opacity: 0
                enabled: false
            }
            PropertyChanges {
                target: rightWidthAdjustmentBar
                opacity: 0
                enabled: false
            }
            PropertyChanges {
                target: viewport.mouse
                z: 5
            }
        },
        State {
            name: Prompter.States.Countdown
            PropertyChanges {
                target: overlay
                state: ReadRegionOverlay.States.Prompting
            }
            PropertyChanges {
                target: countdown
                state: Countdown.States.Running
            }
            PropertyChanges {
                target: timer
                elapsedMilliseconds: 0
            }
            PropertyChanges {
                target: promptingButton
                text: i18n("Skip countdown")
                icon.source: Qt.application.layoutDirection === Qt.RightToLeft ?
                                 "../icons/go-previous.svg" : "../icons/go-next.svg"
            }
            PropertyChanges {
                target: prompter
                z: 1
                __iBackup: 0
                position: position
                timeToArival: 0
                focus: true
            }
            PropertyChanges {
                target: editor
                selectByMouse: false
                activeFocusOnPress: true
            }
            PropertyChanges {
                target: leftWidthAdjustmentBar
                opacity: 0
                enabled: false
            }
            PropertyChanges {
                target: rightWidthAdjustmentBar
                opacity: 0
                enabled: false
            }
            PropertyChanges {
                target: viewport.mouse
                z: 5
            }
        },
        State {
            name: Prompter.States.Prompting
            PropertyChanges {
                target: overlay
                state: ReadRegionOverlay.States.Prompting
            }
            PropertyChanges {
                target: timer
                running: prompter.__play && prompter.__velocity>0
                elapsedMilliseconds: 0
            }
            PropertyChanges {
                target: promptingButton
                text: i18n("Return to edit mode")
                icon.source: Qt.application.layoutDirection === Qt.LeftToRight ?
                                 "../icons/edit-undo.svg" : "../icons/edit-redo.svg"
            }
            PropertyChanges {
                target: prompter
                z: 1
                __i: __iDefault
                __iBackup: 0
                position: prompter.__destination
                focus: true
                __play: true
                timeToArival: __timeToArival
            }
            PropertyChanges {
                target: editor
                selectByMouse: false
                focus: false
                activeFocusOnPress: false
            }
            PropertyChanges {
                target: decreaseVelocityButton
                enabled: true
            }
            PropertyChanges {
                target: increaseVelocityButton
                enabled: true
            }
            PropertyChanges {
                target: leftWidthAdjustmentBar
                opacity: 0
                enabled: false
            }
            PropertyChanges {
                target: rightWidthAdjustmentBar
                opacity: 0
                enabled: false
            }
            PropertyChanges {
                target: limitedMouse
                enabled: true
            }
            PropertyChanges {
                target: viewport.mouse
                z: 5
            }
        }
    ]
    state: Prompter.States.Editing
    onStateChanged: {
        setCursorAtCurrentPosition()
        var pos = prompter.position
        position = pos
        timer.updateTimer()
    }

    transitions: [
        Transition {
            to: Prompter.States.Standby
            ScriptAction  {
                // Jump into position
                script: {
                    // Auto frame to current line
                    position = editor.cursorRectangle.y - (overlay.__readRegionPlacement*(overlay.height-overlay.readRegionHeight)+overlay.readRegionHeight/2) + 1
                    //timer.stopTimer()
                }
            }
        },
        Transition {
            to: Prompter.States.Prompting
            ScriptAction  {
                // Jump into position
                script: {
                    timer.startTimer();
                    cursorAutoHide.hide();
                    cursorAutoHide.restart();
                }
            }
        },
        Transition {
            to: Prompter.States.Editing
            ScriptAction  {
                script: {
                    timer.stopTimer()
                }
            }
        },
        Transition {
            from: Prompter.States.Prompting
            to: Prompter.States.Editing
            ScriptAction  {
                script: {
                    if (prompter.__i>0)
                        __iDefault = prompter.__i;
                    cursorAutoHide.reset();
                }
            }
        }
    ]
}
