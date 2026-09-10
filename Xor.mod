MODULE Xor;
IMPORT SYSTEM;

PROCEDURE xor*(x, y : INTEGER): INTEGER;
VAR
    xSet, ySet : SET;
BEGIN
    SYSTEM.GET(SYSTEM.ADR(x), xSet);
    SYSTEM.GET(SYSTEM.ADR(y), ySet);

    xSet := xSet / ySet;
    RETURN SYSTEM.VAL(INTEGER, xSet);
END xor;

END Xor.
