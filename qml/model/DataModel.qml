import QtQuick 2.0

import Qt.labs.settings 1.1
import QtQuick.LocalStorage 2.12

import Slippi 1.0

Item {
  id: dataModel

  property alias settings: settings

  readonly property string replayFolder: settings.replayFolder

  readonly property var allFiles: Utils.listFiles(replayFolder, ["*.slp"], true)

  property var db: null

  property int dbUpdater: 0
  readonly property int totalReplays: getNumReplays(dbUpdater)
  readonly property int totalReplaysByPlayer: getNumReplaysByPlayer(dbUpdater, slippiCode)
  readonly property int totalReplaysByPlayerWithResult: getNumReplaysByPlayerWithResult(dbUpdater, slippiCode)
  readonly property int totalReplaysWonByPlayer: getNumReplaysWonByPlayer(dbUpdater, slippiCode)
  readonly property int totalReplaysByPlayerWithTie: totalReplaysByPlayer - totalReplaysByPlayerWithResult

  property bool progressCancelled: false
  property int numFilesSucceeded: 0
  property int numFilesFailed: 0
  property int numFilesProcessing: 0
  readonly property int numFilesProcessed: numFilesSucceeded + numFilesFailed
  readonly property bool isProcessing: !progressCancelled && numFilesProcessed < numFilesProcessing
  readonly property real processProgress: isProcessing ? numFilesProcessed / numFilesProcessing : 0

  property alias slippiCode: settings.slippiCode

  onIsProcessingChanged: {
    if(!isProcessing) {
      dbUpdaterChanged() // refresh bindings
    }
  }

  Component.onCompleted: {
    db = LocalStorage.openDatabaseSync("SlippiStatsDB", "1.0", "Slippi Stats DB", 1000000)

    db.transaction(createTablesTx)

    console.log("DB open", db, db.version)
  }

  Settings {
    id: settings
    property string replayFolder
    property string slippiCode
  }

  SlippiParser {
    id: parser

    onReplayParsed: analyzeReplay(filePath, replay)
    onReplayFailedToParse: {
      console.warn("Could not parse replay", filePath, ":", errorMessage)
      numFilesFailed++
    }
  }

  function createTablesTx(tx) {
    tx.executeSql("create table if not exists Replays (
id integer not null primary key,
date date,
stageName text,
stageId integer,
winnerPort integer,
duration integer
    )")

    tx.executeSql("create table if not exists Players (
port integer,
replayId integer,
slippiName text,
slippiCode text,
cssTag text,
startStocks integer,
endStocks integer,
endPercent integer,
isWinner bool,
primary key(replayId, port),
foreign key(replayId) references replays(id)
    )")
  }

  function analyzeReplay(fileName, replay) {
    db.transaction(function(tx) {
      var winnerIndex = replay.winningPlayerIndex
      var winnerTag = winnerIndex >= 0 ? replay.players[winnerIndex].slippiName : null

      tx.executeSql("insert or replace into Replays (id, date, stageName, stageId, winnerPort, duration)
                     values (?, ?, ?, ?, ?, ?)",
                    [
                      replay.uniqueId,
                      replay.date,
                      replay.stageName,
                      replay.stageId,
                      winnerIndex,
                      replay.gameDuration
                    ])

      replay.players.forEach(function(player) {
        tx.executeSql("insert or replace into Players (port, replayId, slippiName, slippiCode, cssTag, startStocks, endStocks, endPercent, isWinner)
                       values (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                      [
                        player.port,
                        replay.uniqueId,
                        player.slippiName,
                        player.slippiCode,
                        player.inGameTag,
                        player.startStocks,
                        player.endStocks,
                        player.endPercent,
                        player.isWinner
                      ])
      })
    })

    numFilesSucceeded++
  }

  function parseReplays(replayFiles) {
    numFilesSucceeded = 0
    numFilesFailed = 0
    numFilesProcessing = replayFiles.length
    progressCancelled = false
    replayFiles.forEach(parseReplay)
  }

  function parseReplay(fileName) {
    parser.parseReplay(fileName)
  }

  function readFromDb(callback, defaultValue) {
    var res = defaultValue

    db.readTransaction(function(tx) {
      try {
         res = callback(tx)
      }
      catch(ex) {
        // table doesn't yet exist, ignore

        console.warn("DB error", ex)
      }
    })

    return res
  }

  function getNumReplays() {
    return readFromDb(function(tx) {
      var results = tx.executeSql("select count(*) c from Replays")

      return results.rows.item(0).c
    }, 0)
  }

  function getNumReplaysByPlayer() {
    if(slippiCode == "") {
      return 0
    }

    return readFromDb(function(tx) {
      var results = tx.executeSql("select count(*) c from replays r join players p on p.replayId = r.id where p.slippiCode = ?", [slippiCode])

      return results.rows.item(0).c
    }, 0)
  }

  function getNumReplaysByPlayerWithResult() {
    if(slippiCode == "") {
      return 0
    }

    return readFromDb(function(tx) {
      var results = tx.executeSql("select count(*) c from replays r join players p on p.replayId = r.id where r.winnerPort >= 0 and p.slippiCode = ?", [slippiCode])

      return results.rows.item(0).c
    }, 0)
  }

  function getNumReplaysWonByPlayer() {
    if(slippiCode == "") {
      return 0
    }

    return readFromDb(function(tx) {
      var results = tx.executeSql("select count(*) c from replays r join players p on p.replayId = r.id where p.isWinner and p.slippiCode = ?", [slippiCode])

      return results.rows.item(0).c
    }, 0)
  }

  function getAverageGameDuration() {
    return readFromDb(function(tx) {
      var results = tx.executeSql("select avg(duration) d from Replays")

      return results.rows.item(0).d || 0
    }, 0)
  }

  function getStageAmount(stageId) {
    return readFromDb(function(tx) {
      var results = tx.executeSql("select count(*) c from Replays where stageId = ?", [stageId])

      return results.rows.item(0).c
    }, 0)
  }

  function getOtherStageAmount(stageIds) {
    return readFromDb(function(tx) {
      var results = tx.executeSql(qsTr("select count(*) c from Replays where stageId not in (%1)")
                                  .arg(stageIds.map(_ => "?").join(",")), // add one question mark placeholder per argument
                                  stageIds)

      return results.rows.item(0).c
    }, 0)
  }

  function getTopPlayerTags(max) {
    return readFromDb(function(tx) {
      var results = tx.executeSql("select slippiName, count(*) c from Players where slippiName is not null and slippiName is not \"\" group by slippiName order by c desc limit ?", [max])

      console.log("results", results.rows.length)

      var result = []
      for (var i = 0; i < results.rows.length; i++) {
        result.push({
                      tag: results.rows.item(i).slippiName,
                      count: results.rows.item(i).c
                    })
      }

      return result
    }, [])
  }

  function cancelAll() {
    parser.cancelAll()
  }

  function clearDatabase() {
    db.transaction(function(tx) {
      tx.executeSql("delete from Replays")
    })

    dbUpdaterChanged() // refresh bindings
  }

  function formatPercentage(amount) {
    return qsTr("%1 %").arg((amount * 100).toFixed(2))
  }
}
