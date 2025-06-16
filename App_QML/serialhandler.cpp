#include "serialhandler.h"

SerialHandler::SerialHandler(QObject *parent) : QObject(parent),
    serial(new QSerialPort(this)),
    m_isConnected(false)
{
    refreshPorts();

    QObject::connect(serial, &QSerialPort::readyRead, this, &SerialHandler::handleReadyRead);
    QObject::connect(serial, &QSerialPort::errorOccurred, this, &SerialHandler::handleError);
}

SerialHandler::~SerialHandler()
{
    if (serial->isOpen()) {
        serial->close();
    }
}

QString SerialHandler::currentPort() const
{
    return m_currentPort;
}

void SerialHandler::setCurrentPort(const QString &port)
{
    if (m_currentPort != port) {
        m_currentPort = port;
        emit currentPortChanged(port);
    }
}

bool SerialHandler::isConnected() const
{
    return m_isConnected;
}

QStringList SerialHandler::availablePorts() const
{
    return m_availablePorts;
}

void SerialHandler::connectToPort()
{
    if (m_currentPort.isEmpty()) {
        emit errorOccurred("No port selected");
        return;
    }

    if (serial->isOpen()) {
        serial->close();
    }

    serial->setPortName(m_currentPort);
    serial->setBaudRate(QSerialPort::Baud115200);
    serial->setDataBits(QSerialPort::Data8);
    serial->setParity(QSerialPort::NoParity);
    serial->setStopBits(QSerialPort::OneStop);
    serial->setFlowControl(QSerialPort::NoFlowControl);

    if (serial->open(QIODevice::ReadWrite)) {
        m_isConnected = true;
        emit isConnectedChanged(true);
    } else {
        emit errorOccurred(serial->errorString());
    }
}

void SerialHandler::disconnectFromPort()
{
    if (serial->isOpen()) {
        serial->close();
    }
    m_isConnected = false;
    emit isConnectedChanged(false);
}

void SerialHandler::refreshPorts()
{
    m_availablePorts.clear();
    const auto ports = QSerialPortInfo::availablePorts();
    for (const QSerialPortInfo &port : ports) {
        m_availablePorts.append(port.portName());
    }
    emit availablePortsChanged(m_availablePorts);
}

void SerialHandler::sendData(const QString &data)
{
    if (!serial->isOpen()) {
        emit errorOccurred("Port not open");
        return;
    }

    QByteArray bytes = data.toUtf8();
    serial->write(bytes);
}

void SerialHandler::handleReadyRead()
{
    QByteArray data = serial->readAll();
    emit dataReceived(QString::fromUtf8(data));
}

void SerialHandler::handleError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError) {
        return;
    }

    emit errorOccurred(serial->errorString());

    if (error != QSerialPort::NotOpenError) {
        disconnectFromPort();
    }
}
