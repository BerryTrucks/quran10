#include "precompiled.h"

#include "Offloader.h"
#include "AppLogFetcher.h"
#include "CommonConstants.h"
#include "IOUtils.h"
#include "Logger.h"
#include "Persistance.h"
#include "QueueDownloader.h"
#include "QueryId.h"
#include "TextUtils.h"
#include "ThreadUtils.h"

#define TAFSIR_MIME_IMAGE "imageSource"

namespace quran {

using namespace canadainc;

Offloader::Offloader(Persistance* persist, QueueDownloader* queue, QObject* parent) :
        QObject(parent), m_persist(persist), m_queue(queue)
{
}


void Offloader::decorateTafsir(bb::cascades::ArrayDataModel* adm, QString const& defaultImage)
{
    for (int i = adm->size()-1; i >= 0; i--)
    {
        QVariantMap qvm = adm->value(i).toMap();
        QString body = qvm.value("body").toString();

        if ( body.endsWith("mp3") ) {
            qvm[TAFSIR_MIME_IMAGE] = "images/list/mime_mp3.png";
        } else if ( body.endsWith("doc") || body.endsWith("docx") ) {
            qvm[TAFSIR_MIME_IMAGE] = "images/list/mime_doc.png";
        } else if ( body.endsWith("pdf") ) {
            qvm[TAFSIR_MIME_IMAGE] = "images/list/mime_pdf.png";
        } else {
            qvm[TAFSIR_MIME_IMAGE] = defaultImage;
        }

        adm->replace(i, qvm);
    }
}


QString Offloader::textualizeAyats(bb::cascades::DataModel* adm, QVariantList const& selectedIndices, QString const& chapterTitle, bool showTranslation)
{
    QVariantMap first = adm->data( selectedIndices.first().toList() ).toMap();
    QVariantMap last = adm->data( selectedIndices.last().toList() ).toMap();
    int firstChapter = first.value(KEY_CHAPTER_ID).toInt();
    int lastChapter = last.value(KEY_CHAPTER_ID).toInt();
    int firstVerse = first.value(KEY_VERSE_ID).toInt();
    int lastVerse = last.value(KEY_VERSE_ID).toInt();

    QString footer;
    QStringList ayats;
    QStringList translations;

    if (firstChapter == lastChapter)
    {
        if (firstVerse == lastVerse) {
            footer = QString("%1 %2:%3").arg(chapterTitle).arg(firstChapter).arg(firstVerse);
        } else {
            footer = QString("%1 %2:%3-%4").arg(chapterTitle).arg(firstChapter).arg(firstVerse).arg(lastVerse);
        }
    } else {
        footer = QString("%1:%2-%3:%4").arg(firstChapter).arg(firstVerse).arg(lastChapter).arg(lastVerse);
    }

    int n = selectedIndices.size();

    for (int i = 0; i < n; i++)
    {
        QVariantMap current = adm->data( selectedIndices[i].toList() ).toMap();
        ayats << current.value("arabic").toString();

        if (showTranslation) {
            translations << current.value("translation").toString();
        }
    }

    return ayats.join("\n")+"\n\n"+translations.join("\n")+"\n\n"+footer;
}


void Offloader::addToHomeScreen(int chapter, int verse, QString const& label)
{
    LOGGER(chapter << verse << label);

    bool added = bb::platform::HomeScreen().addShortcut( QString("asset:///images/menu/ic_mushaf.png"), TextUtils::sanitize(label), QString("quran://%1/%2").arg(chapter).arg(verse) );
    QString toastMessage = tr("Added %1 to home screen").arg(label);
    QString icon = "images/menu/ic_home.png";

    if (!added) {
        toastMessage = tr("Could not add %1 to home screen").arg(label);
        icon = "images/dropdown/suite_changes_cancel.png";

        AppLogFetcher::getInstance()->record("FailedAddHome", label);
    }

    m_persist->showToast(toastMessage, icon);
}


void Offloader::addToHomeScreen(qint64 suitePageId, QString const& label)
{
    LOGGER(suitePageId << label);

    bool added = bb::platform::HomeScreen().addShortcut( QString("asset:///images/list/ic_tafsir.png"), TextUtils::sanitize(label), QString("quran://tafsir/%1").arg(suitePageId) );
    QString toastMessage = tr("Added %1 to home screen").arg(label);
    QString icon = "asset:///images/menu/ic_home.png";

    if (!added) {
        toastMessage = tr("Could not add %1 to home screen").arg(label);
        icon = ASSET_YELLOW_DELETE;

        AppLogFetcher::getInstance()->record("FailedAddHome", label);
    }

    m_persist->showToast(toastMessage, icon);
}


QVariantList Offloader::removeOutOfRange(QVariantList input, int fromChapter, int fromVerse, int toChapter, int toVerse) {
    return ThreadUtils::removeOutOfRange(input, fromChapter, fromVerse, toChapter, toVerse);
}


QVariantList Offloader::normalizeJuzs(QVariantList const& source) {
    return ThreadUtils::normalizeJuzs(source);
}


void Offloader::searchGoogle(QString const& query)
{
    LOGGER(query);

    if ( !query.isRightToLeft() )
    {
        QVariantMap q;
        q[COOKIE_GOOGLE_SEARCH] = true;

        QUrl url;
        url.setScheme("https");
        url.setHost("ajax.googleapis.com");
        url.setPath("ajax/services/search/web");
        url.addQueryItem("v", "1.0");
        url.addQueryItem("q", query);

        q[URI_KEY] = url;
        q[KEY_TRANSFER_NAME] = tr("Google Search: %1").arg(query);

        m_queue->process(q, true);
    } else {
        LOGGER("IgnoreRTL");
    }
}


Offloader::~Offloader()
{
}

} /* namespace quran */
