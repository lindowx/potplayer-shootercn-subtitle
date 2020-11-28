/*
    shooter.cn subtitle search by lindowx
*/

// void OnInitialize()
// void OnFinalize()
// string GetTitle()                                                                 -> get title for UI
// string GetVersion                                                                -> get version for manage
// string GetDesc()                                                                    -> get detail information
// string GetLoginTitle()                                                            -> get title for login dialog
// string GetLoginDesc()                                                            -> get desc for login dialog
// string GetUserText()                                                                -> get user text for login dialog
// string GetPasswordText()                                                            -> get password text for login dialog
// string ServerCheck(string User, string Pass)                                     -> server check
// string ServerLogin(string User, string Pass)                                     -> login
// void ServerLogout()                                                                 -> logout
//------------------------------------------------------------------------------------------------
// string GetLanguages()                                                            -> get support language
// string SubtitleWebSearch(string MovieFileName, dictionary MovieMetaData)            -> search subtitle via web browser
// array<dictionary> SubtitleSearch(string MovieFileName, dictionary MovieMetaData)    -> search subtitle
// string SubtitleDownload(string id)                                                -> download subtitle
// string GetUploadFormat()                                                            -> upload format
// string SubtitleUpload(string MovieFileName, dictionary MovieMetaData, string SubtitleName, string SubtitleContent)    -> upload subtitle

array<array<string>> LangTable = 
{
    { "zh", "中文" }
};

string GetTitle()
{
    return "shooter.cn";
}

string GetVersion()
{
    return "1";
}

string GetDesc()
{
    return "https://lindowx.me";
}

string GetLanguages()
{
    string ret = "";
    
    for (int i = 0, len = LangTable.size(); i < len; i++)
    {
        if (ret.empty()) ret = LangTable[i][0];
        else ret = ret + "," + LangTable[i][0];
    }
    return ret;
}

void AssignItem(dictionary &dst, JsonValue &in src, string dst_key, string src_key = "")
{
    if (src_key.empty()) src_key = dst_key;
    if (src[src_key].isString()) dst[dst_key] = src[src_key].asString();
    else if (src[src_key].isInt64()) dst[dst_key] = src[src_key].asInt64();    
}

string CalcFileHash(string MovieFileName)
{
    string fileHash = "";
    uintptr f = HostFileOpen(MovieFileName);
    if( f > 0 ) 
    {
        int64 fsize = HostFileLength(f);
        if (fsize >= 8192) {
            array<int64> offsets = {
                4096,
                fsize / 3 * 2,
                fsize / 3,
                fsize - 8192,
            };

            for (int i = 0, len = offsets.size(); i < len; i++)
            {
                HostFileSeek(f, offsets[i]);
                string chunkData = HostFileRead(f, 4096);
                string chunkHash = HostHashMD5(chunkData);
                if (!fileHash.isEmpty()) {
                    fileHash = fileHash + ";";
                }
                fileHash = fileHash + chunkHash;
            }
        }
        HostFileClose(f);
    }

    return fileHash;
}

array<dictionary> SubtitleSearch(string MovieFileName, dictionary MovieMetaData)
{
    string title = string(MovieMetaData["title"]);
    array<dictionary> ret;
    string api = "https://www.shooter.cn/api/subapi.php";
    string fileHash = CalcFileHash(MovieFileName);
    string pathinfo = HostUrlEncode(MovieFileName);
    const string postData = "filehash=" + HostUrlEncode(fileHash) + "&pathinfo=" + pathinfo + "&format=json&lang=chn";
    string json = HostUrlGetString(api + "?" + postData, "", "", "shooterDoPost=1");

    JsonReader Reader;
    JsonValue Root;

    if (Reader.parse(json, Root) && Root.isArray())
    {
        for (int i = 0, len = Root.size(); i < len; i++)
        {
            JsonValue subtitle = Root[i];
            dictionary item;

            if(subtitle.isObject())
            {
                JsonValue stFiles = subtitle["Files"];
                if (stFiles.isArray())
                {
                    JsonValue subtitleFileInfo = stFiles[0];
                    if (subtitleFileInfo.isObject()) {
                        item["id"] = "shooter-" + subtitleFileInfo["Link"].asString();
                        item["title"] = title;
                        item["lang"] = "zh";
                        AssignItem(item, subtitleFileInfo, "url", "Link");
                    }
                }
            }

            ret.insertLast(item);
        }
    }
    
    return ret;
}

string SubtitleDownload(string download)
{
    return HostUrlGetString(download);
}
