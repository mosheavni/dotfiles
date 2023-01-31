#!/usr/local/bin/python3
import iterm2
import iterm2.util
from math import floor, ceil
import sys


def get_size(refsize, cursize, width=None, height=None):
    """in percentage 0-100"""
    new = iterm2.util.Size(cursize.width, cursize.height)
    if width is not None:
        new.width = floor(refsize.width * width / 100)
    if height is not None:
        new.height = floor(refsize.height * height / 100)
    return new


def set_session_size(app, refsize, session, width=None, height=None):
    """in percentage 0-100"""
    session = app.get_session_by_id(
        session.session_id
    )  # to make sure to have as current as possible size
    old = session.grid_size
    new = get_size(refsize, old, width, height)
    session.preferred_size = new
    # print(
    #     f"set session size ({width}, {height}): width: {old.width} -> {new.width}, height: {old.height} -> {new.height}"
    # )
    return app.get_session_by_id(session.session_id)


async def main(connection):
    app = await iterm2.async_get_app(connection)
    bottom = app.current_terminal_window.current_tab.current_session
    _, tab = app.get_window_and_tab_for_session(bottom)

    bottom_grid_size = bottom.grid_size
    top = await bottom.async_split_pane(vertical=False, before=True)
    top_grid_size = top.grid_size
    await bottom.async_activate()
    await top.async_send_text(
        text=f"""watch 'kubectl get pods --sort-by=.metadata.creationTimestamp | grep {cmd_flags} "{search_term}"'\n""",
        suppress_broadcast=False,
    )
    set_session_size(app, bottom_grid_size, bottom, height=70)
    set_session_size(app, top_grid_size, top, height=40)
    tab = app.get_tab_by_id(tab.tab_id)
    await tab.async_update_layout()


search_term = ".*"
cmd_flags = ""

if len(sys.argv) == 2:
    search_term = sys.argv[1]

if len(sys.argv) == 3:
    cmd_flags = sys.argv[1]
    search_term = sys.argv[2]

print(f"Searching for {search_term} pods")
iterm2.run_until_complete(main)
