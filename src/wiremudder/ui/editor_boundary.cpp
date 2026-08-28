// WireMudder Editor Boundary (EP-012 M2) - implementation.
#include "src/wiremudder/ui/editor_boundary.h"

#include <algorithm>

namespace wiremudder::ui {

SpellcheckCore::SpellcheckCore()
{
    // Small embedded dictionary for deterministic behavior.
    const char* words[] = {"look", "north",     "south", "east", "west", "open",   "close", "say", "tell", "shout", "get",
                           "drop", "inventory", "score", "help", "quit", "attack", "cast",  "buy", "sell", "wear",  "remove"};
    for (const char* w : words)
        dict_.insert(QString::fromLatin1(w));
}

bool SpellcheckCore::isKnown(const QString& word) const
{
    return dict_.contains(word.toLower());
}

int SpellcheckCore::levenshtein(const QString& a, const QString& b)
{
    const int m = a.size();
    const int n = b.size();
    QList<QList<int>> d(m + 1, QList<int>(n + 1, 0));
    for (int i = 0; i <= m; ++i)
        d[i][0] = i;
    for (int j = 0; j <= n; ++j)
        d[0][j] = j;
    for (int i = 1; i <= m; ++i) {
        for (int j = 1; j <= n; ++j) {
            const int cost = (a.at(i - 1) == b.at(j - 1)) ? 0 : 1;
            d[i][j] = std::min({d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost});
        }
    }
    return d[m][n];
}

QStringList SpellcheckCore::suggest(const QString& word, int maxDistance, int maxSuggestions) const
{
    QList<QPair<int, QString>> scored;
    const QString lower = word.toLower();
    for (const QString& w : dict_) {
        const int dist = levenshtein(lower, w);
        if (dist <= maxDistance)
            scored.append({dist, w});
    }
    std::sort(scored.begin(), scored.end(), [](const QPair<int, QString>& a, const QPair<int, QString>& b) {
        if (a.first != b.first)
            return a.first < b.first;
        return a.second < b.second;
    });
    QStringList out;
    for (const auto& s : scored) {
        out << s.second;
        if (out.size() >= maxSuggestions)
            break;
    }
    return out;
}

QString SpellcheckCore::autocorrect(const QString& word, int maxDistance) const
{
    const QString lower = word.toLower();
    for (const auto& c : corrections_) {
        if (c.first == lower)
            return c.second;
    }
    const QStringList s = suggest(lower, maxDistance, 1);
    return s.isEmpty() ? word : s.first();
}

void SpellcheckCore::addWord(const QString& word)
{
    dict_.insert(word.toLower());
}

void SpellcheckCore::addCorrection(const QString& wrong, const QString& right)
{
    corrections_.append({wrong.toLower(), right});
}

void CompletionCore::add(const QString& item)
{
    items_.insert(item);
}

QStringList CompletionCore::candidates(const QString& prefix, int maxCandidates) const
{
    QStringList out;
    for (const QString& item : items_) {
        if (item.startsWith(prefix, Qt::CaseInsensitive))
            out << item;
        if (out.size() >= maxCandidates)
            break;
    }
    out.sort(Qt::CaseInsensitive);
    return out;
}

} // namespace wiremudder::ui
