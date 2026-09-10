MODULE Xor;
IMPORT SYSTEM;

PROCEDURE xor*(x, y : INTEGER): INTEGER;
VAR
    xSet, ySet : SET;
BEGIN
    xSet := SYSTEM.VAL(SET, x);
    ySet := SYSTEM.VAL(SET, y);

    xSet := xSet / ySet;
    RETURN SYSTEM.VAL(INTEGER, xSet);
END xor;

END Xor.
