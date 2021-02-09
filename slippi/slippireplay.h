#ifndef SLIPPIREPLAY_H
#define SLIPPIREPLAY_H

#include <QObject>
#include <QDateTime>
#include <QVariant>

#include "analysis.h"

struct PlayerData : public QObject {
  Q_OBJECT

  Q_PROPERTY(QString slippiName MEMBER m_slippiName)
  Q_PROPERTY(QString slippiCode MEMBER m_slippiCode)
  Q_PROPERTY(QString inGameTag MEMBER m_inGameTag)
  Q_PROPERTY(int charId MEMBER m_charId)
  Q_PROPERTY(int startStocks MEMBER m_startStocks)
  Q_PROPERTY(int endStocks MEMBER m_endStocks)
  Q_PROPERTY(int endPercent MEMBER m_endPercent)
  Q_PROPERTY(int port MEMBER m_port)
  Q_PROPERTY(bool isWinner MEMBER m_isWinner)

public:
  PlayerData(QObject *parent);

private:
  QString m_slippiName, m_slippiCode, m_inGameTag;
  int m_charId, m_startStocks, m_endStocks, m_endPercent, m_port;
  bool m_isWinner;

  friend class SlippiReplay;
};

class SlippiReplay : public QObject
{
  Q_OBJECT

  Q_PROPERTY(qint64 uniqueId MEMBER m_uniqueId NOTIFY parsedFromAnalysis)
  Q_PROPERTY(QDateTime date MEMBER m_date NOTIFY parsedFromAnalysis)
  Q_PROPERTY(int stageId MEMBER m_stageId NOTIFY parsedFromAnalysis)
  Q_PROPERTY(int gameDuration MEMBER m_gameDuration NOTIFY parsedFromAnalysis)

  Q_PROPERTY(QVariantList players MEMBER m_players NOTIFY parsedFromAnalysis)
  Q_PROPERTY(int winningPlayerIndex MEMBER m_winningPlayerIndex NOTIFY parsedFromAnalysis)

public:
  explicit SlippiReplay(QObject *parent = nullptr);
  ~SlippiReplay();

  void fromAnalysis(slip::Analysis *analysis);

signals:
  void parsedFromAnalysis();

  void parsedFromAna(qint64 uniqueId);

private:
  QString m_stageName;
  int m_stageId;
  int m_gameDuration;
  QDateTime m_date;
  qint64 m_uniqueId;

  QVariantList m_players;
  int m_winningPlayerIndex;
};

#endif // SLIPPIREPLAY_H
