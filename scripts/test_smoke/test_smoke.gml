/// @description Smoke test — proves the GMTL harness runs end-to-end.
suite(function () {
    section("Harness", function () {
        it("runs and passes a basic assertion", function () {
            expect(1 + 1).toBe(2);
        });

        each("can use each() for table cases", function (_a, _b) {
            expect(_a + _b).toBe(3);
        }, [[1, 2], [0, 3]]);
    });
});
