const eslintJs = require("@eslint/js");
const jestPlugin = require("eslint-plugin-jest");
const lwcConfig = require("@salesforce/eslint-config-lwc/recommended");
const globals = require("globals");

module.exports = [
  eslintJs.configs.recommended,
  ...lwcConfig,

  // LWC configuration with override for LWC test files
  {
    files: ["**/lwc/**/*.test.js"],
    rules: {
      "@lwc/lwc/no-unexpected-wire-adapter-usages": "off"
    },
    languageOptions: {
      globals: {
        ...globals.node
      }
    }
  },

  // Jest mocks configuration
  {
    files: ["**/jest-mocks/**/*.js"],
    languageOptions: {
      sourceType: "module",
      ecmaVersion: "latest",
      globals: {
        ...globals.node,
        ...globals.es2021,
        ...jestPlugin.environments.globals.globals
      }
    },
    plugins: {
      jest: jestPlugin
    }
  }
];
