#ifndef QUERYID_H_
#define QUERYID_H_

#include <qobjectdefs.h>

namespace quran {

class QueryId
{
    Q_GADGET
    Q_ENUMS(Type)

public:
    enum Type {
        AddBioLink,
        AddIndividual,
        AddLocation,
        AddQuote,
        AddStudent,
        AddTafsir,
        AddTafsirPage,
        AddTeacher,
        AddWebsite,
        ClearAllBookmarks,
        EditIndividual,
        EditLocation,
        EditQuote,
        EditTafsir,
        EditTafsirPage,
        FetchAdjacentAyat,
        FetchAllAyats,
        FetchAllBookmarks,
        FetchAllChapterAyatCount,
        FetchAllChapters,
        FetchAllDuaa,
        FetchAllIndividuals,
        FetchAllLocations,
        FetchAllOrigins,
        FetchAllQuotes,
        FetchAllRecitations,
        FetchAllTafsir,
        FetchAllTafsirForSuite,
        FetchAllWebsites,
        FetchAyat,
        FetchAyats,
        FetchAyatsForTafsir,
        FetchBio,
        FetchBioMetadata,
        FetchChapters,
        FetchJuz,
        FetchLastProgress,
        FetchIndividualData,
        FetchPageNumbers,
        FetchQuote,
        FetchRandomAyat,
        FetchRandomQuote,
        FetchSimilarAyatContent,
        FetchStudents,
        FetchSurahHeader,
        FetchTafsirContent,
        FetchTafsirCountForAyat,
        FetchTafsirForAyat,
        FetchTafsirForSurah,
        FetchTafsirHeader,
        FetchTeachers,
        FetchTransliteration,
        LinkAyatsToTafsir,
        LinkingAyatsToTafsir,
        RemoveBioLink,
        RemoveBookmark,
		RemoveIndividual,
        RemoveLocation,
        RemoveQuote,
        RemoveStudent,
        RemoveTafsir,
        RemoveTafsirPage,
        RemoveTeacher,
        RemoveWebsite,
        ReplacingIndividual,
        ReplaceIndividual,
        SaveBookmark,
        SaveLastProgress,
        SaveLegacyBookmarks,
        SearchAyats,
        SearchIndividuals,
        SearchQuote,
        SearchTafsir,
        SettingUpBookmarks,
        SettingUpTafsir,
        SetupBookmarks,
        SetupTafsir,
        UnlinkAyatsFromTafsir,
        UpdateTafsirLink
    };
};

}

#endif /* QUERYID_H_ */
