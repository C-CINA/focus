#ifndef IMAGEVIEWER_H
#define IMAGEVIEWER_H

#include <QFrame>
#include <QWidget>

#include "MrcHeaderDisplay.h"

class QLabel;
class QScrollArea;
class QScrollBar;
class QStackedWidget;

class ImageViewer : public QFrame {
    Q_OBJECT

public:
    ImageViewer(const QString& workDir, const QString& notFoundMessage="File not selected", QWidget* parent=0);
    void loadFile(const QString& file, bool loadInfo=false, const QString& notFoundMessage="");

private slots:
    void progressDialog();
    void clearWidgets();
    
signals:
    void setProgress(int value);

protected:
    void mouseDoubleClickEvent(QMouseEvent *event);

private:
    void setText(const QString& text);
    void setNotSupportedText();

    QStackedWidget* widgets;
    
    QLabel* imageLabel;
    MrcHeaderDisplay* mrcInfo;
            
    QString notFoundMessage_;
    QString workingDir_;
    QString fileName_;
};

#endif