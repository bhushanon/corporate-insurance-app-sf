public with sharing class PremiumCalculator {
    /**
     * Calculates total premium based on base and add-ons.
     * Supports override logic via custom handler if provided.
     */
    public static Decimal calculatePremium(Decimal basePremium, List<Decimal> addonPremiums, PremiumOverrideHandler overrideHandler) {
        if (basePremium == null) basePremium = 0;
        Decimal totalAddons = 0;
        if (addonPremiums != null) {
            for (Decimal addon : addonPremiums) {
                if (addon != null) totalAddons += addon;
            }
        }
        Decimal calculated = basePremium + totalAddons;
        // Allow override logic if handler is provided
        if (overrideHandler != null) {
            return overrideHandler.overridePremium(basePremium, addonPremiums, calculated);
        }
        return calculated.setScale(2);
    }

    // Interface for override logic
    public interface PremiumOverrideHandler {
        Decimal overridePremium(Decimal base, List<Decimal> addons, Decimal calculated);
    }
}