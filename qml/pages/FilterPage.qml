import QtQuick 2.0
import QtQuick.Controls 2.12

import Felgo 3.0

import "../model/stats"
import "../views/controls"
import "../views/grids"
import "../views/icons"
import "../views/visual"

Page {
  id: filterPage
  title: qsTr("Filtering")

  property ReplayStats stats: null

  FilterInfoItem {
    id: header
    stats: filterPage.stats
    showResetButton: true
  }

  AppFlickable {
    anchors.fill: parent
    anchors.topMargin: header.height

    // somehow the list doesn't scroll all the way to the bottom so add extra spacing
    contentHeight: content.height + dp(18)

    Column {
      id: content
      width: parent.width

      AppTabBar {
        id: filterTabs
        contentContainer: filterSwipe

        AppTabButton {
          text: "Game"
        }
        AppTabButton {
          text: "Me"
        }
        AppTabButton {
          text: "Opponent"
        }
      }

      SwipeView {
        id: filterSwipe
        width: parent.width
        height: currentItem ? currentItem.implicitHeight : dp(500)

        GameFilterOptions {
          filter: dataModel.gameFilter
          stats: dataModel.stats
        }

        PlayerFilterOptions {
          id: filterOptionsMe
          me: true
          filter: dataModel.playerFilter
        }

        PlayerFilterOptions {
          id: filterOptionsOpponent
          me: false
          filter: dataModel.opponentFilter
        }
      }
    }
  }
}
