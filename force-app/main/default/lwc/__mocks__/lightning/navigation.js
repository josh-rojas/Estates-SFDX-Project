/**
 * Mock for lightning/navigation module
 * Provides NavigationMixin and Navigate symbol for LWC tests
 */

export const Navigate = Symbol("Navigate");

export const NavigationMixin = (Base) => {
  return class extends Base {
    [Navigate] = jest.fn();
  };
};

