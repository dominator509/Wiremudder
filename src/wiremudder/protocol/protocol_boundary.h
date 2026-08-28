// WireMudder Protocol Boundary (EP-011)
//
// Declares the C++ surface for protocol negotiation and capability
// detection. Implements a real Telnet IAC parser for the option
// negotiation matrix (WILL/WONT/DO/DONT + subnegotiation) covering
// GMCP, MSDP, MSP, MXP, ATCP, and the research-status protocols
// (MCP, Pueblo, Simutronics/GSL).
#pragma once

#include <QByteArray>
#include <QList>
#include <QString>
#include <QSet>
#include <QHash>

namespace wiremudder::protocol {

// Telnet command bytes (RFC 854).
namespace cmd {
constexpr quint8 IAC = 0xFF;
constexpr quint8 DONT = 0xFE;
constexpr quint8 DO = 0xFD;
constexpr quint8 WONT = 0xFC;
constexpr quint8 WILL = 0xFB;
constexpr quint8 SB = 0xFA;
constexpr quint8 SE = 0xF0;
} // namespace cmd

// Telnet option numbers (IANA).
namespace opt {
constexpr quint8 BINARY = 0;
constexpr quint8 ECHO = 1;
constexpr quint8 SGA = 3;
constexpr quint8 NAWS = 31;
constexpr quint8 TERMINAL = 24;
constexpr quint8 CHARSET = 42;
constexpr quint8 MSSP = 70;
constexpr quint8 MXP = 91;
constexpr quint8 MSP = 90;
constexpr quint8 GMCP = 201;
constexpr quint8 MSDP = 69;
constexpr quint8 ATCP = 200;
} // namespace opt

// A single parsed negotiation event.
struct NegotiationEvent
{
    quint8 verb;        // IAC verb (DO/DONT/WILL/WONT/SB)
    quint8 option;      // option number
    QByteArray subdata; // subnegotiation payload (verb==SB)
    int position;       // byte offset in the input stream
};

// Capability detection result.
struct Capability
{
    QString protocol; // "GMCP", "MSDP", "MXP", "MSP", "ATCP", "MSSP"
    bool negotiated;  // observed WILL/DO for the option
    QString status;   // "negotiated" | "declined" | "research"
    QString note;
};

// Parse a byte stream into negotiation events. Malformed input is
// bounded: an unterminated SB sequence is truncated at a declared cap.
QList<NegotiationEvent> parseIac(const QByteArray& data, int maxSb = 4096);

// Detect capabilities from an event list.
QList<Capability> detectCapabilities(const QList<NegotiationEvent>& events);

// Human-readable protocol name for an option number.
QString optionName(quint8 option);

} // namespace wiremudder::protocol
