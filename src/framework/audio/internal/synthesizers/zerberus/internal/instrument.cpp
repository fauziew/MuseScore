/*
 * SPDX-License-Identifier: GPL-3.0-only
 * MuseScore-CLA-applies
 *
 * MuseScore
 * Music Composition & Notation
 *
 * Copyright (C) 2021 MuseScore BVBA and others
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <math.h>
#include <QFile>
#include <QFileInfo>
#include <QStringList>
#include <QVector>

#include "audiofile/audiofile.h"
#include "thirdparty/qzip/qzipreader_p.h"

#include "instrument.h"
#include "zone.h"
#include "sample.h"

#include "framework/global/xmlreader.h"

using namespace mu::zerberus;
using namespace mu::framework;

QByteArray ZInstrument::buf;
int ZInstrument::idx;

//---------------------------------------------------------
//   Sample
//---------------------------------------------------------

Sample::~Sample()
{
    delete[] _data;
}

//---------------------------------------------------------
//   readSample
//---------------------------------------------------------

Sample* ZInstrument::readSample(const QString& s, MQZipReader* uz)
{
    if (uz) {
        QVector<MQZipReader::FileInfo> fi = uz->fileInfoList();

        buf = uz->fileData(s);
        if (buf.isEmpty()) {
            printf("Sample::read: cannot read sample data <%s>\n", qPrintable(s));
            return 0;
        }
    } else {
        QFile f(s);
        if (!f.open(QIODevice::ReadOnly)) {
            printf("Sample::read: open <%s> failed\n", qPrintable(s));
            return 0;
        }
        buf = f.readAll();
    }

    AudioFile a;
    if (!a.open(buf)) {
        printf("open <%s> failed: %s\n", qPrintable(s), a.error());
        return 0;
    }

    int channel = a.channels();
    sf_count_t frames  = a.frames();
    int sr      = a.samplerate();

    short* data = new short[(frames + 3) * channel];
    Sample* sa  = new Sample(channel, data, frames, sr);
    sa->setLoopStart(a.loopStart());
    sa->setLoopEnd(a.loopEnd());
    sa->setLoopMode(a.loopMode());

    if (frames != a.readData(data + channel, frames)) {
        qDebug("Sample read failed: %s\n", a.error());
        delete sa;
        sa = 0;
    }
    for (int i = 0; i < channel; ++i) {
        data[i]                        = data[channel + i];
        data[(frames - 1) * channel + i] = data[(frames - 3) * channel + i];
        data[(frames - 2) * channel + i] = data[(frames - 3) * channel + i];
    }
    return sa;
}

//---------------------------------------------------------
//   ZInstrument
//---------------------------------------------------------

ZInstrument::ZInstrument(Zerberus* z)
{
    zerberus  = z;
    for (int i =0; i < 128; i++) {
        _setcc[i] = -1;
    }
    _program  = -1;
    _refCount = 0;
}

//---------------------------------------------------------
//   ZInstrument
//---------------------------------------------------------

ZInstrument::~ZInstrument()
{
    for (Zone* z : _zones) {
        delete z;
    }
}

//---------------------------------------------------------
//   load
//    return true on success
//---------------------------------------------------------

bool ZInstrument::load(const QString& path)
{
    instrumentPath = path;
    QFileInfo fi(path);
    _name = fi.completeBaseName();
    if (fi.isFile()) {
        return loadFromFile(path);
    }
    if (fi.isDir()) {
        return loadFromDir(path);
    }
    qDebug("not file nor dir %s", qPrintable(path));
    return false;
}

//---------------------------------------------------------
//   loadFromDir
//---------------------------------------------------------

bool ZInstrument::loadFromDir(const QString& s)
{
    QFile f(s + "/orchestra.xml");
    if (!f.open(QIODevice::ReadOnly)) {
        printf("cannot load orchestra.xml in <%s>\n", qPrintable(s));
        return false;
    }
    QByteArray buff = f.readAll();
    if (buff.isEmpty()) {
        printf("Instrument::loadFromFile: orchestra.xml is empty\n");
        return false;
    }
    return read(buff, 0, s);
}

//---------------------------------------------------------
//   loadFromFile
//---------------------------------------------------------

bool ZInstrument::loadFromFile(const QString& path)
{
    if (path.endsWith(".sfz")) {
        return loadSfz(path);
    }
    if (!path.endsWith(".msoz")) {
        printf("<%s> not a orchestra file\n", qPrintable(path));
        return false;
    }
    MQZipReader uz(path);
    if (!uz.exists()) {
        printf("Instrument::load: %s not found\n", qPrintable(path));
        return false;
    }
    QByteArray buff = uz.fileData("orchestra.xml");
    if (buff.isEmpty()) {
        printf("Instrument::loadFromFile: orchestra.xml not found\n");
        return false;
    }
    return read(buff, &uz, QString());
}

//---------------------------------------------------------
//   read
//    read orchestra
//---------------------------------------------------------

bool ZInstrument::read(const QByteArray& buff, MQZipReader* /*uz*/, const QString& /*path*/)
{
    XmlReader e(buff);
    while (e.readNextStartElement()) {
        if (e.tagName() == "MuseSynth") {
            while (e.readNextStartElement()) {
                if (e.tagName() == "Instrument") {
                    // if (!read(e, uz, path))
                    //      return false;
                } else {
                    e.skipCurrentElement();
                }
            }
        } else {
            e.skipCurrentElement();
        }
    }
    return true;
}
