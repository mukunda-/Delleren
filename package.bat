@REM This is for copying docs,binaries, and stuff to the release packages

@rmdir /S /Q release\Delleren
@mkdir release
@mkdir release\Delleren
xcopy /Y /S Libs release\Delleren\Libs\
xcopy /Y /S sounds release\Delleren\sounds\
xcopy /Y *.lua release\Delleren\
xcopy /Y *.toc release\Delleren\
xcopy /Y *.xml release\Delleren\
xcopy /Y Delleren.toc release\Delleren\
xcopy /Y LICENSE-ACE.TXT release\Delleren\
xcopy /Y LICENSE-DELLEREN.TXT release\Delleren\
xcopy /Y manual.txt release\Delleren\

@pause