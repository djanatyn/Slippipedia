import QtQuick 2.0
import QtQuick.Layouts 1.0
import Felgo 3.0
import Slippipedia 1.0

Item {
  id: analyticsListView

  property var model

  property string infoText
  property string infoDetailText

  property bool showsCharacters: false
  property bool showsStages: false
  property bool sortByWinRate: true

  signal showList(var id)
  signal showStats(var id)

  // bugfix - sorting doesn't work otherwise
  Component.onCompleted: Qt.callLater(() => {
                                        sortByWinRate = !sortByWinRate
                                        sortByWinRate = !sortByWinRate
                                      })

  property Sorter winRateSorter: RoleSorter {
    roleName: "winRate"
    ascendingOrder: false
  }

  property Sorter countSorter: RoleSorter {
    roleName: "gamesFinished"
    ascendingOrder: false
  }

  property Sorter idSorter: RoleSorter {
    roleName: "id"
    ascendingOrder: false
  }

  AppListItem {
    id: header
    Layout.fillWidth: true

    text: infoText
    detailText: infoDetailText + " " + (sortByWinRate
                                        ? "Ordered by your win rate."
                                        : "Ordered by number of games.")

    enabled: false
    backgroundColor: Theme.backgroundColor
  }

  Item {
    anchors.fill: parent
    anchors.topMargin: header.height + dp(Theme.contentPadding)

    AppListView {
      id: listView

      emptyText.text: "No replays found."

      model: SortFilterProxyModel {
        id: sfpm

        sorters: sortByWinRate ? [winRateSorter] : []

        sourceModel: JsonListModel {
          id: listModel
          source: analyticsListView.model
          keyField: "id"
        }
      }

      // this shows empty sections
    //  section.labelPositioning: ViewSection.InlineLabels | ViewSection.CurrentLabelAtStart

      section.property: "section"
      section.delegate: Rectangle {
        width: listView.width
        height: dp(60)
        color: Theme.backgroundColor
        visible: !!section

        AppText {
          text: section || "?"
          anchors.left: parent.left
          anchors.bottom: parent.bottom
          anchors.margins: dp(Theme.contentPadding)
          font.pixelSize: sp(24)
        }

        Divider { }
      }

      delegate: RowLayout {
        width: listView.width
        height: dp(72)

        property bool showsCharName: width > dp(540) || (!showsStages && !showsCharacters)

        Item {
          Layout.preferredHeight: 1
          Layout.preferredWidth: dp(Theme.contentPadding)
        }

        CharacterIcon {
          charId: ~~model.id
          visible: showsCharacters
          Layout.preferredWidth: height * 66/56
          Layout.preferredHeight: parent.height - dp(Theme.contentPadding)
        }

        StageIcon {
          stageId: ~~model.id
          visible: showsStages
          Layout.preferredWidth: height * 62/48
          Layout.preferredHeight: parent.height - dp(Theme.contentPadding)
        }

        Item {
          visible: showsStages || showsCharacters
          Layout.preferredHeight: 1
          Layout.preferredWidth: dp(Theme.contentPadding) / 2
        }

        AppText {
          Layout.alignment: Qt.AlignVCenter
          Layout.preferredWidth: dp(100)
          font.pixelSize: sp(20)
          color: Theme.tintColor
          visible: showsCharName

          text: model && model.name || "?"
        }

        Item {
          Layout.preferredHeight: 1
          Layout.preferredWidth: dp(Theme.contentPadding)
          visible: showsCharName
        }

        StatsInfoItem {
          Layout.preferredHeight: dp(48)
          Layout.fillWidth: true

          textColor: Theme.textColor

          height: undefined // remove binding since height is handled by layout

          stats: model

          onShowList: analyticsListView.showList(model.id)
          onShowStats: analyticsListView.showStats(model.id)
        }

        Item {
          Layout.preferredHeight: 1
          Layout.preferredWidth: dp(Theme.contentPadding)
        }
      }
    }
  }
}
