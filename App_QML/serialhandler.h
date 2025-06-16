#ifndef SERIALHANDLER_H
#define SERIALHANDLER_H

#include <QObject>
#include <QSerialPort>
#include <QSerialPortInfo>
#include <QDebug>

class SerialHandler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentPort READ currentPort WRITE setCurrentPort NOTIFY currentPortChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)
    Q_PROPERTY(QStringList availablePorts READ availablePorts NOTIFY availablePortsChanged)

public:
    explicit SerialHandler(QObject *parent = nullptr);
    ~SerialHandler();

    QString currentPort() const;
    void setCurrentPort(const QString &port);
    bool isConnected() const;
    QStringList availablePorts() const;

    Q_INVOKABLE void connectToPort();
    Q_INVOKABLE void disconnectFromPort();
    Q_INVOKABLE void refreshPorts();
    Q_INVOKABLE void sendData(const QString &data);

signals:
    void currentPortChanged(const QString &port);
    void isConnectedChanged(bool connected);
    void availablePortsChanged(const QStringList &ports);
    void dataReceived(const QString &data);
    void errorOccurred(const QString &error);

private slots:
    void handleReadyRead();
    void handleError(QSerialPort::SerialPortError error);

private:
    QSerialPort *serial;
    QString m_currentPort;
    bool m_isConnected;
    QStringList m_availablePorts;
};

#endif // SERIALHANDLER_H
