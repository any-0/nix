export const TerminalBell = async () => ({
  event: async ({ event }) => {
    if (process.env.OPENCODE_CLIENT === "acp") return

    if (event.type === "session.idle" || event.type === "permission.asked") {
      process.stdout.write("\x07")
    }
  },
})
