#include <QString>
#include <QDebug>

int main() {
    qDebug().noquote() << QString("Hello WinDeployQt");
    return 0;
}
