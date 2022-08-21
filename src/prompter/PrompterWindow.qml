/****************************************************************************
 **
 ** QPrompt
 ** Copyright (C) 2021-2022 Javier O. Cordero Pérez
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

import QtQuick 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.15
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0

import com.cuperino.qprompt.prompterwindow 1.0

QPromptWindow {
    title: i18n("Prompter")
//    transientParent: root
    modality: Qt.NonModal
    visible: true
    //flags: Qt.FramelessWindowHint
    color: "transparent"
//    onClosing: {
//    }
//    Settings {
//        category: "prompterWindow"
//    }
//    PrompterView {
//        id: externalViewport
//        anchors.fill: parent
//        prompter.state: Prompter.States.Prompting
//        prompter.performFileOperations: false
//    }
//    Item {
//        id: decreaseVelocityButton
//    }
//    Item {
//        id: increaseVelocityButton
//    }
}
