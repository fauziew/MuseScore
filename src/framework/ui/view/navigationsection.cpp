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
#include "navigationsection.h"

#include <algorithm>

#include "log.h"

using namespace mu::ui;

NavigationSection::NavigationSection(QObject* parent)
    : AbstractNavigation(parent)
{
}

NavigationSection::~NavigationSection()
{
    navigationController()->unreg(this);
}

void NavigationSection::componentComplete()
{
    //! NOTE Reg after set properties.
    IF_ASSERT_FAILED(!m_name.isEmpty()) {
        return;
    }

    IF_ASSERT_FAILED(order() > -1) {
        return;
    }

    navigationController()->reg(this);
}

QString NavigationSection::name() const
{
    return AbstractNavigation::name();
}

const INavigation::Index& NavigationSection::index() const
{
    return AbstractNavigation::index();
}

mu::async::Channel<INavigation::Index> NavigationSection::indexChanged() const
{
    return AbstractNavigation::indexChanged();
}

bool NavigationSection::enabled() const
{
    return AbstractNavigation::enabled();
}

mu::async::Channel<bool> NavigationSection::enabledChanged() const
{
    return AbstractNavigation::enabledChanged();
}

bool NavigationSection::active() const
{
    return AbstractNavigation::active();
}

void NavigationSection::setActive(bool arg)
{
    AbstractNavigation::setActive(arg);
}

mu::async::Channel<bool> NavigationSection::activeChanged() const
{
    return AbstractNavigation::activeChanged();
}

void NavigationSection::onEvent(EventPtr e)
{
    AbstractNavigation::onEvent(e);
}

void NavigationSection::addPanel(NavigationPanel* panel)
{
    TRACEFUNC;
    IF_ASSERT_FAILED(panel) {
        return;
    }

    m_panels.insert(panel);

    panel->forceActiveRequested().onReceive(this, [this](const PanelControl& subcon) {
        m_forceActiveRequested.send(std::make_tuple(this, std::get<0>(subcon), std::get<1>(subcon)));
    });

    if (m_panelsListChanged.isConnected()) {
        m_panelsListChanged.notify();
    }
}

mu::async::Channel<SectionPanelControl> NavigationSection::forceActiveRequested() const
{
    return m_forceActiveRequested;
}

void NavigationSection::removePanel(NavigationPanel* panel)
{
    TRACEFUNC;
    IF_ASSERT_FAILED(panel) {
        return;
    }

    m_panels.erase(panel);
    panel->forceActiveRequested().resetOnReceive(this);

    if (m_panelsListChanged.isConnected()) {
        m_panelsListChanged.notify();
    }
}

const std::set<INavigationPanel*>& NavigationSection::panels() const
{
    return m_panels;
}

mu::async::Notification NavigationSection::panelsListChanged() const
{
    return m_panelsListChanged;
}
