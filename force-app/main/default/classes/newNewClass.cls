public with sharing class NewNewClass {
    public static Decimal fahrenheitToCelsius(Decimal fh) {
        Decimal cs = (fh - 32) * 5/9;
        return cs.setScale(2);
    }
}
// making change for pull request into QA
//edit 