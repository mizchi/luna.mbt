import { defineAuth } from "void/auth";

export default defineAuth(({ defaults }) => ({
  ...defaults,
  emailAndPassword: { ...defaults.emailAndPassword, enabled: true, minPasswordLength: 12 },
}));
