/*
    Xunlei Kankan subtitle search by lindowx
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
    { "zh", "中文" },
    { "en", "英文" }
};

string GetTitle()
{
    return "迅雷看看";
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
        string chunkData = "";
        if (fsize < 0xF000) {
            chunkData = HostFileRead(f, fsize);
            fileHash = HostHashSHA1(chunkData);
        } else {
            chunkData = HostFileRead(f, 0x5000);
            HostFileSeek(f, fsize/3);
            chunkData += HostFileRead(f, 0x5000);
            HostFileSeek(f, fsize - 0x5000);
            chunkData += HostFileRead(f, 0x5000);
            fileHash = HostHashSHA1(chunkData);
        }
        HostFileClose(f);
    }

    return fileHash.MakeUpper();
}

array<dictionary> SubtitleSearch(string MovieFileName, dictionary MovieMetaData)
{
    string title = string(MovieMetaData["title"]);
    array<dictionary> ret;
    string fileHash = CalcFileHash(MovieFileName);
    string json = HostUrlGetString("http://sub.xmp.sandai.net:8000/subxl/" + fileHash + ".json");

    JsonReader Reader;
    JsonValue Root;

    if (Reader.parse(json, Root) && Root.isObject())
    {
        JsonValue sublist = Root["sublist"];
        if (sublist.isArray())
        {
            for (int i = 0, len = sublist.size(); i < len; i++)
            {
                JsonValue subtitle = sublist[i];
                dictionary item;

                if(subtitle.isObject())
                {
                    item["id"] = subtitle["scid"].asString();
                    item["title"] = subtitle["sname"].asString();
                    string lang = subtitle["language"].asString();
                    if (lang == "简体" || lang == "繁体")
                    {
                        item["lang"] = "zh";
                    } else {
                        item["lang"] = "en";
                    }
                    
                    AssignItem(item, subtitle, "url", "surl");
                }

                ret.insertLast(item);
            }
        }
    }
    
    return ret;
}

string SubtitleDownload(string download)
{
    return HostUrlGetString(download);
}
