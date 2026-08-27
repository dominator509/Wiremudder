// WireMudder Protocol Boundary (EP-011) - implementation.
#include "src/wiremudder/protocol/protocol_boundary.h"

namespace wiremudder::protocol {

QString optionName(quint8 option) {
    switch (option) {
    case opt::BINARY:   return QStringLiteral("BINARY");
    case opt::ECHO:     return QStringLiteral("ECHO");
    case opt::SGA:      return QStringLiteral("SGA");
    case opt::NAWS:     return QStringLiteral("NAWS");
    case opt::TERMINAL: return QStringLiteral("TERMINAL-TYPE");
    case opt::CHARSET:  return QStringLiteral("CHARSET");
    case opt::MSSP:     return QStringLiteral("MSSP");
    case opt::MXP:      return QStringLiteral("MXP");
    case opt::MSP:      return QStringLiteral("MSP");
    case opt::GMCP:     return QStringLiteral("GMCP");
    case opt::MSDP:     return QStringLiteral("MSDP");
    case opt::ATCP:     return QStringLiteral("ATCP");
    default:            return QStringLiteral("OPT-%1").arg(option);
    }
}

QList<NegotiationEvent> parseIac(const QByteArray& data, int maxSb) {
    QList<NegotiationEvent> out;
    const char* p = data.constData();
    const int len = data.size();
    int i = 0;
    while (i + 2 < len) {
        if (static_cast<quint8>(p[i]) != cmd::IAC) { ++i; continue; }
        const quint8 verb = static_cast<quint8>(p[i + 1]);
        if (verb == cmd::IAC) { ++i; continue; } // escaped 0xFF
        if (verb == cmd::SB) {
            // subnegotiation: consume until IAC SE (bounded)
            int j = i + 2;
            quint8 sbOpt = 0;
            if (j < len) {
                sbOpt = static_cast<quint8>(p[j]);
                ++j;
            }
            QByteArray sub;
            bool closed = false;
            while (j + 1 < len) {
                if (static_cast<quint8>(p[j]) == cmd::IAC &&
                    static_cast<quint8>(p[j + 1]) == cmd::SE) {
                    out.append({cmd::SB, sbOpt, sub, i});
                    i = j + 2;
                    closed = true;
                    break;
                }
                if (static_cast<quint8>(p[j]) == cmd::IAC &&
                    static_cast<quint8>(p[j + 1]) == cmd::IAC) {
                    sub.append(static_cast<char>(cmd::IAC));
                    j += 2;
                    continue;
                }
                sub.append(p[j]);
                ++j;
                if (sub.size() > maxSb) { // bound runaway subnegotiation
                    out.append({cmd::SB, sbOpt, sub.left(maxSb), i});
                    i = j;
                    closed = true;
                    break;
                }
            }
            if (!closed) {
                // Unterminated SB: report the partial event and stop,
                // guaranteeing forward progress on malformed streams.
                out.append({cmd::SB, sbOpt, sub, i});
                i = len;
            }
            continue;
        }
        if (verb == cmd::DO || verb == cmd::DONT ||
            verb == cmd::WILL || verb == cmd::WONT) {
            if (i + 2 < len) {
                const quint8 option = static_cast<quint8>(p[i + 2]);
                out.append({verb, option, QByteArray(), i});
            }
            i += 3;
            continue;
        }
        ++i;
    }
    return out;
}

QList<Capability> detectCapabilities(const QList<NegotiationEvent>& events) {
    QList<Capability> caps;
    // Map option -> protocol name
    const QHash<quint8, QString> protocolByOption = {
        {opt::GMCP, QStringLiteral("GMCP")},
        {opt::MSDP, QStringLiteral("MSDP")},
        {opt::MXP,  QStringLiteral("MXP")},
        {opt::MSP,  QStringLiteral("MSP")},
        {opt::ATCP, QStringLiteral("ATCP")},
        {opt::MSSP, QStringLiteral("MSSP")},
    };
    const QList<quint8> options = protocolByOption.keys();
    for (quint8 option : options) {
        // Telnet negotiation is stateful: the last verb observed for an
        // option wins (WONT after WILL means the peer changed its mind).
        quint8 lastVerb = 0;
        for (const NegotiationEvent& e : events) {
            if (e.option != option) continue;
            lastVerb = e.verb;
        }
        const bool negotiated =
            (lastVerb == cmd::WILL || lastVerb == cmd::DO);
        const bool declined =
            (lastVerb == cmd::WONT || lastVerb == cmd::DONT);
        Capability c;
        c.protocol = protocolByOption.value(option);
        c.negotiated = negotiated;
        if (negotiated) {
            c.status = QStringLiteral("negotiated");
            c.note = QStringLiteral("observed WILL/DO for option %1").arg(optionName(option));
        } else if (declined) {
            c.status = QStringLiteral("declined");
            c.note = QStringLiteral("observed WONT/DONT for option %1").arg(optionName(option));
        } else {
            c.status = QStringLiteral("absent");
            c.note = QStringLiteral("no negotiation observed for option %1").arg(optionName(option));
        }
        caps.append(c);
    }
    // Research-status protocols (MCP, Pueblo, Simutronics/GSL) have no
    // Telnet option byte in the inherited tree; declared as research.
    for (const QString& p : {QStringLiteral("MCP"), QStringLiteral("PUEBLO"),
                             QStringLiteral("SIMUTRONICS-GSL")}) {
        caps.append({p, false, QStringLiteral("research"),
                     QStringLiteral("no inherited option byte; research decision documented")});
    }
    return caps;
}

} // namespace wiremudder::protocol
