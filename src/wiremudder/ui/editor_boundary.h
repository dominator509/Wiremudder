// WireMudder Editor Boundary (EP-012 M2)
//
// Spellcheck/autocorrect (WM-FEAT-0018) and tab/entity/command-template
// completion (WM-FEAT-0019). Both are deterministic, bounded, and work
// over real dictionaries/registries.
#pragma once

#include <QList>
#include <QSet>
#include <QString>
#include <QStringList>

namespace wiremudder::ui {

// Real spellcheck/autocorrect core: dictionary lookup, Levenshtein
// suggestion, and a small autocorrect map.
class SpellcheckCore
{
public:
    SpellcheckCore();
    bool isKnown(const QString& word) const;
    // Sorted suggestions within maxDistance of the word (maxSuggestions).
    QStringList suggest(const QString& word, int maxDistance = 2, int maxSuggestions = 8) const;
    // Autocorrect: known correction if the word matches the map, else
    // the closest suggestion when within maxDistance, else unchanged.
    QString autocorrect(const QString& word, int maxDistance = 2) const;
    void addWord(const QString& word);
    void addCorrection(const QString& wrong, const QString& right);
    int dictionarySize() const { return dict_.size(); }

private:
    QSet<QString> dict_;
    QList<QPair<QString, QString>> corrections_;
    static int levenshtein(const QString& a, const QString& b);
};

// Tab/entity/command-template completion (WM-FEAT-0019).
class CompletionCore
{
public:
    void add(const QString& item);
    // Prefix candidates, sorted; bounded to maxCandidates.
    QStringList candidates(const QString& prefix, int maxCandidates = 20) const;
    int size() const { return items_.size(); }

private:
    QSet<QString> items_;
};

} // namespace wiremudder::ui
