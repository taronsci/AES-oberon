MODULE Aes;
IMPORT Out, In, Strings, Args, Files, Platform, Constant, Xor;
CONST
    BLOCKSIZE = 16;
TYPE
    AESMatrix = ARRAY 4, 4 OF INTEGER;
    AESKey = ARRAY BLOCKSIZE OF INTEGER;
    IntArrFour =  ARRAY 4 OF INTEGER;
    AESString = ARRAY BLOCKSIZE + 1 OF CHAR;
VAR
    keyText : AESString;
    key : AESKey;
    fullKey: ARRAY 10 OF AESKey;

    f : Files.File;
    r : Files.Rider;

    fOut : Files.File;
    rOut : Files.Rider;

    input, output: ARRAY 32 OF CHAR;
    ch: ARRAY 3 OF CHAR;

PROCEDURE subBytes(VAR text : AESMatrix);
VAR
    i, j : INTEGER;
    row, col : INTEGER;
BEGIN
    FOR i := 0 TO 3 DO
        FOR j := 0 TO 3 DO
            row := text[i][j] DIV 10H;
            col := text[i][j] MOD 10H;
            text[i][j] := Constant.sBox[row][col];
        END;
    END;
END subBytes;

PROCEDURE invSubBytes(VAR text : AESMatrix);
VAR
    i, j : INTEGER;
    row, col : INTEGER;
BEGIN
    FOR i := 0 TO 3 DO
        FOR j := 0 TO 3 DO
            row := text[i][j] DIV 10H;
            col := text[i][j] MOD 10H;
            text[i][j] := Constant.invSBox[row][col];
        END;
    END;
END invSubBytes;

PROCEDURE shiftRows(VAR text: AESMatrix);
VAR
    tmp : INTEGER;
BEGIN
    (* row 1 *)
    tmp := text[1][0];
    text[1][0] := text[1][1];
    text[1][1] := text[1][2];
    text[1][2] := text[1][3];
    text[1][3] := tmp;

    (* row 2 *)
    tmp := text[2][0];
    text[2][0] := text[2][2];
    text[2][2] := tmp;

    tmp := text[2][1];
    text[2][1] := text[2][3];
    text[2][3] := tmp;

    (* row 3 *)
    tmp := text[3][0];
    text[3][0] := text[3][3];
    text[3][3] := text[3][2];
    text[3][2] := text[3][1];
    text[3][1] := tmp;
END shiftRows;

PROCEDURE invShiftRows(VAR text: AESMatrix);
VAR
    tmp : INTEGER;
BEGIN
    (* row 1 *)
    tmp := text[1][3];
    text[1][3] := text[1][2];
    text[1][2] := text[1][1];
    text[1][1] := text[1][0];
    text[1][0] := tmp;

    (* row 2 *)
    tmp := text[2][0];
    text[2][0] := text[2][2];
    text[2][2] := tmp;

    tmp := text[2][1];
    text[2][1] := text[2][3];
    text[2][3] := tmp;

    (* row 3 *)
    tmp := text[3][0];
    text[3][0] := text[3][1];
    text[3][1] := text[3][2];
    text[3][2] := text[3][3];
    text[3][3] := tmp;
END invShiftRows;

PROCEDURE gMul2(x : INTEGER) : INTEGER;
VAR
    result : INTEGER;
BEGIN
    IF x >= 080H THEN
        result := Xor.xor(2 * x, 011BH);
    ELSE
        result := x * 2;
    END;
    RETURN result;
END gMul2;

PROCEDURE gMul3(x : INTEGER): INTEGER;
BEGIN
    RETURN Xor.xor(gMul2(x), x);
END gMul3;

PROCEDURE mixColumns(VAR text : AESMatrix);
VAR
    j : INTEGER;
    a0, a1, a2, a3 : INTEGER;
BEGIN
    FOR j := 0 TO 3 DO
        a0 := text[0][j];
        a1 := text[1][j];
        a2 := text[2][j];
        a3 := text[3][j];

        text[0][j] := Xor.xor(
                        Xor.xor(gMul2(a0), gMul3(a1)),
                        Xor.xor(a2, a3)
                    );
        text[1][j] := Xor.xor(
                        Xor.xor(a0, gMul2(a1)),
                        Xor.xor(gMul3(a2), a3)
                    );
        text[2][j] := Xor.xor(
                        Xor.xor(a0, a1),
                        Xor.xor(gMul2(a2), gMul3(a3))
                    );
        text[3][j] := Xor.xor(
                        Xor.xor(gMul3(a0), a1),
                        Xor.xor(a2, gMul2(a3))
                    );
    END;
END mixColumns;

PROCEDURE gMul9(x : INTEGER) : INTEGER;
VAR
    x2, x4, x8 : INTEGER;
BEGIN
    x2 := gMul2(x);
    x4 := gMul2(x2);
    x8 := gMul2(x4);

    RETURN Xor.xor(x8, x);
END gMul9;

PROCEDURE gMul11(x : INTEGER) : INTEGER;
VAR
    x2, x4, x8 : INTEGER;
BEGIN
    x2 := gMul2(x);
    x4 := gMul2(x2);
    x8 := gMul2(x4);

    RETURN Xor.xor(Xor.xor(x8, x2), x);
END gMul11;

PROCEDURE gMul13(x : INTEGER) : INTEGER;
VAR
    x2, x4, x8 : INTEGER;
BEGIN
    x2 := gMul2(x);
    x4 := gMul2(x2);
    x8 := gMul2(x4);

    RETURN Xor.xor(Xor.xor(x8, x4), x);
END gMul13;

PROCEDURE gMul14(x : INTEGER) : INTEGER;
VAR
    x2, x4, x8 : INTEGER;
BEGIN
    x2 := gMul2(x);
    x4 := gMul2(x2);
    x8 := gMul2(x4);

    RETURN Xor.xor(Xor.xor(x8, x4), x2);
END gMul14;

PROCEDURE invMixColumns(VAR text : AESMatrix);
VAR
    j : INTEGER;
    a0, a1, a2, a3 : INTEGER;
BEGIN (* B-11 D-13 E-14 *)
    FOR j := 0 TO 3 DO
        a0 := text[0][j];
        a1 := text[1][j];
        a2 := text[2][j];
        a3 := text[3][j];

        text[0][j] := Xor.xor(
                        Xor.xor(gMul14(a0), gMul11(a1)),
                        Xor.xor(gMul13(a2), gMul9(a3))
                    );
        text[1][j] := Xor.xor(
                        Xor.xor(gMul9(a0), gMul14(a1)),
                        Xor.xor(gMul11(a2), gMul13(a3))
                    );
        text[2][j] := Xor.xor(
                        Xor.xor(gMul13(a0), gMul9(a1)),
                        Xor.xor(gMul14(a2), gMul11(a3))
                    );
        text[3][j] := Xor.xor(
                        Xor.xor(gMul11(a0), gMul13(a1)),
                        Xor.xor(gMul9(a2), gMul14(a3))
                    );
    END;
END invMixColumns;

PROCEDURE addRoundKey(VAR text : AESMatrix; key : AESKey);
VAR
    i, j : INTEGER;
BEGIN
    FOR i := 0 TO 3 DO
        FOR j := 0 TO 3 DO
            text[i][j] := Xor.xor(text[i][j], key[i + j * 4]);
        END;
    END;
END addRoundKey;

PROCEDURE rotWord(VAR word : IntArrFour);
VAR
    tmp: INTEGER;
BEGIN
    tmp := word[0];
    word[0] := word[1];
    word[1] := word[2];
    word[2] := word[3];
    word[3] := tmp;
END rotWord;

PROCEDURE subWord(VAR word : IntArrFour);
VAR
    i : INTEGER;
    row, col : INTEGER;
BEGIN
    FOR i := 0 TO 3 DO
        row := word[i] DIV 10H;
        col := word[i] MOD 10H;
        word[i] := Constant.sBox[row][col];
    END;
END subWord;

PROCEDURE rCon(VAR word : IntArrFour; round : INTEGER);
BEGIN
    word[0] := Xor.xor(word[0], Constant.roundConst[round]);
END rCon;

PROCEDURE nextKey(VAR key : AESKey; round : INTEGER);
VAR
    i : INTEGER;
    w3: IntArrFour;
BEGIN
    FOR i := 0 TO 3 DO
        w3[i] := key[12 + i];
    END;

    rotWord(w3);
    subWord(w3);
    rCon(w3, round);

    FOR i := 0 TO 3 DO
        key[i] := Xor.xor(w3[i], key[i]);
    END;

    FOR i := 4 TO 15 DO
        key[i] := Xor.xor(key[i - 4], key[i]);
    END;

END nextKey;

PROCEDURE encryptAES(plaintext : AESString; VAR ciphertext : AESString);
VAR
    i, j, idx : INTEGER;
    plainMatrix: AESMatrix;
    nxtKey: AESKey;
BEGIN
    idx := 0;
    FOR i := 0 TO 3 DO
        FOR j := 0 TO 3 DO
            plainMatrix[j, i] := ORD(plaintext[idx]);
            INC(idx);
        END;
    END;

    nxtKey := key;
    addRoundKey(plainMatrix, nxtKey); nextKey(nxtKey, 0);

    FOR i := 1 TO 9 DO
        subBytes(plainMatrix);
        shiftRows(plainMatrix);
        mixColumns(plainMatrix);
        addRoundKey(plainMatrix, nxtKey); nextKey(nxtKey, i);
    END;

    subBytes(plainMatrix);
    shiftRows(plainMatrix);
    addRoundKey(plainMatrix, nxtKey);

    idx := 0;
    FOR i := 0 TO 3 DO
        FOR j := 0 TO 3 DO
            ciphertext[idx] := CHR(plainMatrix[j][i]);
            INC(idx);
        END;
    END;

END encryptAES;

PROCEDURE decryptAES(ciphertext : AESString; VAR plaintext : AESString);
VAR
    i, j, idx : INTEGER;
    cipherMatrix: AESMatrix;
BEGIN
    idx := 0;
    FOR i := 0 TO 3 DO
        FOR j := 0 TO 3 DO
            cipherMatrix[j, i] := ORD(ciphertext[idx]);
            INC(idx);
        END;
    END;

    addRoundKey(cipherMatrix, fullKey[9]);
    invShiftRows(cipherMatrix);
    invSubBytes(cipherMatrix);

    FOR i := 8 TO 0 BY -1 DO
        addRoundKey(cipherMatrix, fullKey[i]);
        invMixColumns(cipherMatrix);
        invShiftRows(cipherMatrix);
        invSubBytes(cipherMatrix);
    END;

    addRoundKey(cipherMatrix, key);

    idx := 0;
    FOR i := 0 TO 3 DO
        FOR j := 0 TO 3 DO
            plaintext[idx] := CHR(cipherMatrix[j][i]);
            INC(idx);
        END;
    END;

END decryptAES;

PROCEDURE encrypt();
VAR
    plaintext : AESString;
    ciphertext : AESString;
    i, diff : LONGINT;
BEGIN
    Files.ReadBytes(r, plaintext, BLOCKSIZE);
    WHILE ~r.eof DO
        encryptAES(plaintext, ciphertext);
        Files.WriteBytes(rOut, ciphertext, BLOCKSIZE);
        Files.ReadBytes(r, plaintext, BLOCKSIZE);
    END;

    diff := r.res;
    IF diff # 15 THEN
        FOR i := BLOCKSIZE - diff TO BLOCKSIZE - 1 DO
            plaintext[i] := CHR(diff);
        END;
    ELSE
        FOR i := 0 TO BLOCKSIZE - 1 DO
            plaintext[i] := CHR(010H);
        END;
    END;

    encryptAES(plaintext, ciphertext);
    Files.WriteBytes(rOut, ciphertext, BLOCKSIZE);

    Files.Register(fOut);
END encrypt;

PROCEDURE checkPadding(plaintext: AESString) : INTEGER;
VAR
    ch, chPrev: CHAR;
    i : INTEGER;
BEGIN
    ch := plaintext[BLOCKSIZE - 1];
    IF (ORD(ch) < 1) OR (ORD(ch) > 16) THEN
        RETURN BLOCKSIZE
    END;

    FOR i := 1 TO ORD(ch) - 1 DO
        chPrev := plaintext[15 - i];
        IF ch # chPrev THEN
            RETURN BLOCKSIZE;
        END;
    END;

    RETURN BLOCKSIZE - ORD(ch);
END checkPadding;

PROCEDURE decrypt();
VAR
    size: INTEGER;
    plaintext : AESString;
    ciphertext : AESString;
BEGIN
    Files.ReadBytes(r, ciphertext, BLOCKSIZE);
    WHILE ~r.eof DO
        decryptAES(ciphertext, plaintext);
        size := checkPadding(plaintext);

        Files.WriteBytes(rOut, plaintext, size);
        Files.ReadBytes(r, ciphertext, BLOCKSIZE);
    END;

    Files.Register(fOut);
END decrypt;

PROCEDURE initKey();
VAR
    i : INTEGER;
BEGIN
    FOR i := 0 TO 15 DO
        key[i] := ORD(keyText[i]);
    END;
END initKey;

PROCEDURE getFullKey();
VAR
    i : INTEGER;
    tmp : AESKey;
BEGIN
    tmp := key;
    FOR i := 0 TO 9 DO
        nextKey(tmp, i);
        fullKey[i] := tmp;
    END;
END getFullKey;

BEGIN
    Args.Get(1, ch);
    IF ch = "-h" THEN
        Out.String("Usage: "); Out.Ln;
        Out.String("./Aes -h"); Out.Ln;
        Out.String("./Aes (-e | -d) INPUT_FILE OUTPUT_FILE"); Out.Ln;
        Out.Ln;
        Out.String("Arguments must be provided in the order shown above."); Out.Ln;
        Out.Ln;
        Out.String("-e    Encrypt INPUT_FILE to OUTPUT_FILE"); Out.Ln;
        Out.String("-d    Decrypt INPUT_FILE to OUTPUT_FILE"); Out.Ln;
        Out.String("-h    Show this help message"); Out.Ln;
        Platform.Exit(0);
    END;

    Out.String("Please input a valid 16 byte key: "); Out.Ln;
    In.Line(keyText);
    IF Strings.Length(keyText) < 16 THEN
        Out.String("Key must not be shorter than 16"); Out.Ln;
        Platform.Exit(1);
    END;
    initKey();

    Args.Get(2, input);
    Args.Get(3, output);

    f := Files.Old(input); (* Open file *)
    fOut := Files.New(output);

    IF f = NIL THEN
        Out.String("Input file doesn't exist"); Out.Ln;
        Platform.Exit(1);
    END;

    Files.Set(r, f, 0);
    Files.Set(rOut, fOut, 0);

    IF ch = "-e" THEN
        Out.String("encrypting file: "); Out.String(input); Out.Ln;
        encrypt();
    ELSIF ch = "-d" THEN
        getFullKey();
        Out.String("decrypting file: "); Out.String(input); Out.Ln;
        decrypt();
    END;
END Aes.
