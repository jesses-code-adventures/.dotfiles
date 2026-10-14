import { Plugin } from '@opencode/plugin';

export const WorkmuxStatusPlugin = Plugin.define({
  id: 'workmux-status',
  setup(ctx) {
    // OpenCode can emit repeated `session.status busy` events for a single turn,
    // and can even emit a stale trailing `busy` after `idle` at the end. Track
    // per-session status so workmux only sees real transitions.
    const lastStatusBySession = new Map<string, string>();
    const acceptBusyBySession = new Map<string, boolean>();
    const workmux = Bun.which('workmux');

    async function setStatus(
      sessionID: string | undefined,
      status: string,
    ) {
      if (!sessionID || !workmux) {
        return;
      }

      const previous = lastStatusBySession.get(sessionID);
      // Ignore the final stale `busy` OpenCode sometimes emits after a session is
      // already done. The next user message re-arms `working` for the new turn.
      if (status === 'working' && acceptBusyBySession.get(sessionID) === false) {
        return;
      }
      if (previous === status) {
        return;
      }

      lastStatusBySession.set(sessionID, status);
      if (status === 'done') {
        acceptBusyBySession.set(sessionID, false);
      } else {
        acceptBusyBySession.set(sessionID, true);
      }

      const proc = Bun.spawn([workmux, 'set-window-status', status], {
        stdout: 'ignore',
        stderr: 'ignore',
      });
      await proc.exited;
    }

    const controller = new AbortController();
    const eventTask = (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          if (event.type === 'session.inbox.enqueued' && event.data.item.type === 'user') {
            acceptBusyBySession.set(event.data.sessionID, true);
          }

          switch (event.type) {
            case 'session.status':
              if (event.data.status.type === 'busy') {
                await setStatus(event.data.sessionID, 'working');
              }
              if (event.data.status.type === 'idle') {
                await setStatus(event.data.sessionID, 'done');
              }
              break;
            case 'permission.asked':
              await setStatus(event.data.sessionID, 'waiting');
              break;
            case 'form.created':
              await setStatus(event.data.form.sessionID, 'waiting');
              break;
            case 'permission.replied':
              await setStatus(event.data.sessionID, 'working');
              break;
            case 'form.replied':
              await setStatus(event.data.sessionID, 'working');
              break;
            case 'session.idle':
              await setStatus(event.data.sessionID, 'done');
              break;
          }
        }
      } catch (error) {
        if (!controller.signal.aborted) {
          console.error('workmux-status event subscription failed', error);
        }
      }
    })();

    return async () => {
      controller.abort();
      await eventTask;
    };
  },
});

export default WorkmuxStatusPlugin;
