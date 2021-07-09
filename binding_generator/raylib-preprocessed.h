# 1 "raylib.h"
# 1 "<built-in>"
# 1 "<command-line>"
# 31 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 32 "<command-line>" 2
# 1 "raylib.h"
# 82 "raylib.h"
# 1 "/usr/lib/gcc/x86_64-linux-gnu/10/include/stdarg.h" 1 3 4
# 40 "/usr/lib/gcc/x86_64-linux-gnu/10/include/stdarg.h" 3 4

# 40 "/usr/lib/gcc/x86_64-linux-gnu/10/include/stdarg.h" 3 4
typedef __builtin_va_list __gnuc_va_list;
# 99 "/usr/lib/gcc/x86_64-linux-gnu/10/include/stdarg.h" 3 4
typedef __gnuc_va_list va_list;
# 83 "raylib.h" 2
# 175 "raylib.h"
# 1 "/usr/lib/gcc/x86_64-linux-gnu/10/include/stdbool.h" 1 3 4
# 176 "raylib.h" 2






# 181 "raylib.h"
typedef struct Vector2 {
    float x;
    float y;
} Vector2;


typedef struct Vector3 {
    float x;
    float y;
    float z;
} Vector3;


typedef struct Vector4 {
    float x;
    float y;
    float z;
    float w;
} Vector4;


typedef Vector4 Quaternion;


typedef struct Matrix {
    float m0, m4, m8, m12;
    float m1, m5, m9, m13;
    float m2, m6, m10, m14;
    float m3, m7, m11, m15;
} Matrix;


typedef struct Color {
    unsigned char r;
    unsigned char g;
    unsigned char b;
    unsigned char a;
} Color;


typedef struct Rectangle {
    float x;
    float y;
    float width;
    float height;
} Rectangle;



typedef struct Image {
    void *data;
    int width;
    int height;
    int mipmaps;
    int format;
} Image;



typedef struct Texture {
    unsigned int id;
    int width;
    int height;
    int mipmaps;
    int format;
} Texture;


typedef Texture Texture2D;


typedef Texture TextureCubemap;


typedef struct RenderTexture {
    unsigned int id;
    Texture texture;
    Texture depth;
} RenderTexture;


typedef RenderTexture RenderTexture2D;


typedef struct NPatchInfo {
    Rectangle source;
    int left;
    int top;
    int right;
    int bottom;
    int layout;
} NPatchInfo;


typedef struct CharInfo {
    int value;
    int offsetX;
    int offsetY;
    int advanceX;
    Image image;
} CharInfo;


typedef struct Font {
    int baseSize;
    int charsCount;
    int charsPadding;
    Texture2D texture;
    Rectangle *recs;
    CharInfo *chars;
} Font;




typedef struct Camera3D {
    Vector3 position;
    Vector3 target;
    Vector3 up;
    float fovy;
    int projection;
} Camera3D;

typedef Camera3D Camera;


typedef struct Camera2D {
    Vector2 offset;
    Vector2 target;
    float rotation;
    float zoom;
} Camera2D;



typedef struct Mesh {
    int vertexCount;
    int triangleCount;


    float *vertices;
    float *texcoords;
    float *texcoords2;
    float *normals;
    float *tangents;
    unsigned char *colors;
    unsigned short *indices;


    float *animVertices;
    float *animNormals;
    int *boneIds;
    float *boneWeights;


    unsigned int vaoId;
    unsigned int *vboId;
} Mesh;


typedef struct Shader {
    unsigned int id;
    int *locs;
} Shader;


typedef struct MaterialMap {
    Texture2D texture;
    Color color;
    float value;
} MaterialMap;


typedef struct Material {
    Shader shader;
    MaterialMap *maps;
    float params[4];
} Material;


typedef struct Transform {
    Vector3 translation;
    Quaternion rotation;
    Vector3 scale;
} Transform;


typedef struct BoneInfo {
    char name[32];
    int parent;
} BoneInfo;


typedef struct Model {
    Matrix transform;

    int meshCount;
    int materialCount;
    Mesh *meshes;
    Material *materials;
    int *meshMaterial;


    int boneCount;
    BoneInfo *bones;
    Transform *bindPose;
} Model;


typedef struct ModelAnimation {
    int boneCount;
    int frameCount;
    BoneInfo *bones;
    Transform **framePoses;
} ModelAnimation;


typedef struct Ray {
    Vector3 position;
    Vector3 direction;
} Ray;


typedef struct RayHitInfo {
    
# 405 "raylib.h" 3 4
   _Bool 
# 405 "raylib.h"
        hit;
    float distance;
    Vector3 position;
    Vector3 normal;
} RayHitInfo;


typedef struct BoundingBox {
    Vector3 min;
    Vector3 max;
} BoundingBox;


typedef struct Wave {
    unsigned int sampleCount;
    unsigned int sampleRate;
    unsigned int sampleSize;
    unsigned int channels;
    void *data;
} Wave;

typedef struct rAudioBuffer rAudioBuffer;



typedef struct AudioStream {
    rAudioBuffer *buffer;

    unsigned int sampleRate;
    unsigned int sampleSize;
    unsigned int channels;
} AudioStream;


typedef struct Sound {
    AudioStream stream;
    unsigned int sampleCount;
} Sound;



typedef struct Music {
    AudioStream stream;
    unsigned int sampleCount;
    
# 449 "raylib.h" 3 4
   _Bool 
# 449 "raylib.h"
        looping;

    int ctxType;
    void *ctxData;
} Music;


typedef struct VrDeviceInfo {
    int hResolution;
    int vResolution;
    float hScreenSize;
    float vScreenSize;
    float vScreenCenter;
    float eyeToScreenDistance;
    float lensSeparationDistance;
    float interpupillaryDistance;
    float lensDistortionValues[4];
    float chromaAbCorrection[4];
} VrDeviceInfo;


typedef struct VrStereoConfig {
    Matrix projection[2];
    Matrix viewOffset[2];
    float leftLensCenter[2];
    float rightLensCenter[2];
    float leftScreenCenter[2];
    float rightScreenCenter[2];
    float scale[2];
    float scaleIn[2];
} VrStereoConfig;







typedef enum {
    FLAG_VSYNC_HINT = 0x00000040,
    FLAG_FULLSCREEN_MODE = 0x00000002,
    FLAG_WINDOW_RESIZABLE = 0x00000004,
    FLAG_WINDOW_UNDECORATED = 0x00000008,
    FLAG_WINDOW_HIDDEN = 0x00000080,
    FLAG_WINDOW_MINIMIZED = 0x00000200,
    FLAG_WINDOW_MAXIMIZED = 0x00000400,
    FLAG_WINDOW_UNFOCUSED = 0x00000800,
    FLAG_WINDOW_TOPMOST = 0x00001000,
    FLAG_WINDOW_ALWAYS_RUN = 0x00000100,
    FLAG_WINDOW_TRANSPARENT = 0x00000010,
    FLAG_WINDOW_HIGHDPI = 0x00002000,
    FLAG_MSAA_4X_HINT = 0x00000020,
    FLAG_INTERLACED_HINT = 0x00010000
} ConfigFlags;


typedef enum {
    LOG_ALL = 0,
    LOG_TRACE,
    LOG_DEBUG,
    LOG_INFO,
    LOG_WARNING,
    LOG_ERROR,
    LOG_FATAL,
    LOG_NONE
} TraceLogLevel;




typedef enum {
    KEY_NULL = 0,

    KEY_APOSTROPHE = 39,
    KEY_COMMA = 44,
    KEY_MINUS = 45,
    KEY_PERIOD = 46,
    KEY_SLASH = 47,
    KEY_ZERO = 48,
    KEY_ONE = 49,
    KEY_TWO = 50,
    KEY_THREE = 51,
    KEY_FOUR = 52,
    KEY_FIVE = 53,
    KEY_SIX = 54,
    KEY_SEVEN = 55,
    KEY_EIGHT = 56,
    KEY_NINE = 57,
    KEY_SEMICOLON = 59,
    KEY_EQUAL = 61,
    KEY_A = 65,
    KEY_B = 66,
    KEY_C = 67,
    KEY_D = 68,
    KEY_E = 69,
    KEY_F = 70,
    KEY_G = 71,
    KEY_H = 72,
    KEY_I = 73,
    KEY_J = 74,
    KEY_K = 75,
    KEY_L = 76,
    KEY_M = 77,
    KEY_N = 78,
    KEY_O = 79,
    KEY_P = 80,
    KEY_Q = 81,
    KEY_R = 82,
    KEY_S = 83,
    KEY_T = 84,
    KEY_U = 85,
    KEY_V = 86,
    KEY_W = 87,
    KEY_X = 88,
    KEY_Y = 89,
    KEY_Z = 90,


    KEY_SPACE = 32,
    KEY_ESCAPE = 256,
    KEY_ENTER = 257,
    KEY_TAB = 258,
    KEY_BACKSPACE = 259,
    KEY_INSERT = 260,
    KEY_DELETE = 261,
    KEY_RIGHT = 262,
    KEY_LEFT = 263,
    KEY_DOWN = 264,
    KEY_UP = 265,
    KEY_PAGE_UP = 266,
    KEY_PAGE_DOWN = 267,
    KEY_HOME = 268,
    KEY_END = 269,
    KEY_CAPS_LOCK = 280,
    KEY_SCROLL_LOCK = 281,
    KEY_NUM_LOCK = 282,
    KEY_PRINT_SCREEN = 283,
    KEY_PAUSE = 284,
    KEY_F1 = 290,
    KEY_F2 = 291,
    KEY_F3 = 292,
    KEY_F4 = 293,
    KEY_F5 = 294,
    KEY_F6 = 295,
    KEY_F7 = 296,
    KEY_F8 = 297,
    KEY_F9 = 298,
    KEY_F10 = 299,
    KEY_F11 = 300,
    KEY_F12 = 301,
    KEY_LEFT_SHIFT = 340,
    KEY_LEFT_CONTROL = 341,
    KEY_LEFT_ALT = 342,
    KEY_LEFT_SUPER = 343,
    KEY_RIGHT_SHIFT = 344,
    KEY_RIGHT_CONTROL = 345,
    KEY_RIGHT_ALT = 346,
    KEY_RIGHT_SUPER = 347,
    KEY_KB_MENU = 348,
    KEY_LEFT_BRACKET = 91,
    KEY_BACKSLASH = 92,
    KEY_RIGHT_BRACKET = 93,
    KEY_GRAVE = 96,


    KEY_KP_0 = 320,
    KEY_KP_1 = 321,
    KEY_KP_2 = 322,
    KEY_KP_3 = 323,
    KEY_KP_4 = 324,
    KEY_KP_5 = 325,
    KEY_KP_6 = 326,
    KEY_KP_7 = 327,
    KEY_KP_8 = 328,
    KEY_KP_9 = 329,
    KEY_KP_DECIMAL = 330,
    KEY_KP_DIVIDE = 331,
    KEY_KP_MULTIPLY = 332,
    KEY_KP_SUBTRACT = 333,
    KEY_KP_ADD = 334,
    KEY_KP_ENTER = 335,
    KEY_KP_EQUAL = 336,

    KEY_BACK = 4,
    KEY_MENU = 82,
    KEY_VOLUME_UP = 24,
    KEY_VOLUME_DOWN = 25
} KeyboardKey;


typedef enum {
    MOUSE_LEFT_BUTTON = 0,
    MOUSE_RIGHT_BUTTON = 1,
    MOUSE_MIDDLE_BUTTON = 2
} MouseButton;


typedef enum {
    MOUSE_CURSOR_DEFAULT = 0,
    MOUSE_CURSOR_ARROW = 1,
    MOUSE_CURSOR_IBEAM = 2,
    MOUSE_CURSOR_CROSSHAIR = 3,
    MOUSE_CURSOR_POINTING_HAND = 4,
    MOUSE_CURSOR_RESIZE_EW = 5,
    MOUSE_CURSOR_RESIZE_NS = 6,
    MOUSE_CURSOR_RESIZE_NWSE = 7,
    MOUSE_CURSOR_RESIZE_NESW = 8,
    MOUSE_CURSOR_RESIZE_ALL = 9,
    MOUSE_CURSOR_NOT_ALLOWED = 10
} MouseCursor;


typedef enum {

    GAMEPAD_BUTTON_UNKNOWN = 0,


    GAMEPAD_BUTTON_LEFT_FACE_UP,
    GAMEPAD_BUTTON_LEFT_FACE_RIGHT,
    GAMEPAD_BUTTON_LEFT_FACE_DOWN,
    GAMEPAD_BUTTON_LEFT_FACE_LEFT,





    GAMEPAD_BUTTON_RIGHT_FACE_UP,
    GAMEPAD_BUTTON_RIGHT_FACE_RIGHT,
    GAMEPAD_BUTTON_RIGHT_FACE_DOWN,
    GAMEPAD_BUTTON_RIGHT_FACE_LEFT,


    GAMEPAD_BUTTON_LEFT_TRIGGER_1,
    GAMEPAD_BUTTON_LEFT_TRIGGER_2,
    GAMEPAD_BUTTON_RIGHT_TRIGGER_1,
    GAMEPAD_BUTTON_RIGHT_TRIGGER_2,


    GAMEPAD_BUTTON_MIDDLE_LEFT,
    GAMEPAD_BUTTON_MIDDLE,
    GAMEPAD_BUTTON_MIDDLE_RIGHT,


    GAMEPAD_BUTTON_LEFT_THUMB,
    GAMEPAD_BUTTON_RIGHT_THUMB
} GamepadButton;


typedef enum {

    GAMEPAD_AXIS_LEFT_X = 0,
    GAMEPAD_AXIS_LEFT_Y = 1,


    GAMEPAD_AXIS_RIGHT_X = 2,
    GAMEPAD_AXIS_RIGHT_Y = 3,


    GAMEPAD_AXIS_LEFT_TRIGGER = 4,
    GAMEPAD_AXIS_RIGHT_TRIGGER = 5
} GamepadAxis;


typedef enum {
    MATERIAL_MAP_ALBEDO = 0,
    MATERIAL_MAP_METALNESS = 1,
    MATERIAL_MAP_NORMAL = 2,
    MATERIAL_MAP_ROUGHNESS = 3,
    MATERIAL_MAP_OCCLUSION,
    MATERIAL_MAP_EMISSION,
    MATERIAL_MAP_HEIGHT,
    MATERIAL_MAP_BRDG,
    MATERIAL_MAP_CUBEMAP,
    MATERIAL_MAP_IRRADIANCE,
    MATERIAL_MAP_PREFILTER
} MaterialMapIndex;





typedef enum {
    SHADER_LOC_VERTEX_POSITION = 0,
    SHADER_LOC_VERTEX_TEXCOORD01,
    SHADER_LOC_VERTEX_TEXCOORD02,
    SHADER_LOC_VERTEX_NORMAL,
    SHADER_LOC_VERTEX_TANGENT,
    SHADER_LOC_VERTEX_COLOR,
    SHADER_LOC_MATRIX_MVP,
    SHADER_LOC_MATRIX_VIEW,
    SHADER_LOC_MATRIX_PROJECTION,
    SHADER_LOC_MATRIX_MODEL,
    SHADER_LOC_MATRIX_NORMAL,
    SHADER_LOC_VECTOR_VIEW,
    SHADER_LOC_COLOR_DIFFUSE,
    SHADER_LOC_COLOR_SPECULAR,
    SHADER_LOC_COLOR_AMBIENT,
    SHADER_LOC_MAP_ALBEDO,
    SHADER_LOC_MAP_METALNESS,
    SHADER_LOC_MAP_NORMAL,
    SHADER_LOC_MAP_ROUGHNESS,
    SHADER_LOC_MAP_OCCLUSION,
    SHADER_LOC_MAP_EMISSION,
    SHADER_LOC_MAP_HEIGHT,
    SHADER_LOC_MAP_CUBEMAP,
    SHADER_LOC_MAP_IRRADIANCE,
    SHADER_LOC_MAP_PREFILTER,
    SHADER_LOC_MAP_BRDF
} ShaderLocationIndex;





typedef enum {
    SHADER_UNIFORM_FLOAT = 0,
    SHADER_UNIFORM_VEC2,
    SHADER_UNIFORM_VEC3,
    SHADER_UNIFORM_VEC4,
    SHADER_UNIFORM_INT,
    SHADER_UNIFORM_IVEC2,
    SHADER_UNIFORM_IVEC3,
    SHADER_UNIFORM_IVEC4,
    SHADER_UNIFORM_SAMPLER2D
} ShaderUniformDataType;



typedef enum {
    PIXELFORMAT_UNCOMPRESSED_GRAYSCALE = 1,
    PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA,
    PIXELFORMAT_UNCOMPRESSED_R5G6B5,
    PIXELFORMAT_UNCOMPRESSED_R8G8B8,
    PIXELFORMAT_UNCOMPRESSED_R5G5B5A1,
    PIXELFORMAT_UNCOMPRESSED_R4G4B4A4,
    PIXELFORMAT_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8,
    PIXELFORMAT_UNCOMPRESSED_R32,
    PIXELFORMAT_UNCOMPRESSED_R32G32B32,
    PIXELFORMAT_UNCOMPRESSED_R32G32B32A32,
    PIXELFORMAT_COMPRESSED_DXT1_RGB,
    PIXELFORMAT_COMPRESSED_DXT1_RGBA,
    PIXELFORMAT_COMPRESSED_DXT3_RGBA,
    PIXELFORMAT_COMPRESSED_DXT5_RGBA,
    PIXELFORMAT_COMPRESSED_ETC1_RGB,
    PIXELFORMAT_COMPRESSED_ETC2_RGB,
    PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA,
    PIXELFORMAT_COMPRESSED_PVRT_RGB,
    PIXELFORMAT_COMPRESSED_PVRT_RGBA,
    PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA,
    PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA
} PixelFormat;




typedef enum {
    TEXTURE_FILTER_POINT = 0,
    TEXTURE_FILTER_BILINEAR,
    TEXTURE_FILTER_TRILINEAR,
    TEXTURE_FILTER_ANISOTROPIC_4X,
    TEXTURE_FILTER_ANISOTROPIC_8X,
    TEXTURE_FILTER_ANISOTROPIC_16X,
} TextureFilter;


typedef enum {
    TEXTURE_WRAP_REPEAT = 0,
    TEXTURE_WRAP_CLAMP,
    TEXTURE_WRAP_MIRROR_REPEAT,
    TEXTURE_WRAP_MIRROR_CLAMP
} TextureWrap;


typedef enum {
    CUBEMAP_LAYOUT_AUTO_DETECT = 0,
    CUBEMAP_LAYOUT_LINE_VERTICAL,
    CUBEMAP_LAYOUT_LINE_HORIZONTAL,
    CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR,
    CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE,
    CUBEMAP_LAYOUT_PANORAMA
} CubemapLayout;


typedef enum {
    FONT_DEFAULT = 0,
    FONT_BITMAP,
    FONT_SDF
} FontType;


typedef enum {
    BLEND_ALPHA = 0,
    BLEND_ADDITIVE,
    BLEND_MULTIPLIED,
    BLEND_ADD_COLORS,
    BLEND_SUBTRACT_COLORS,
    BLEND_CUSTOM
} BlendMode;



typedef enum {
    GESTURE_NONE = 0,
    GESTURE_TAP = 1,
    GESTURE_DOUBLETAP = 2,
    GESTURE_HOLD = 4,
    GESTURE_DRAG = 8,
    GESTURE_SWIPE_RIGHT = 16,
    GESTURE_SWIPE_LEFT = 32,
    GESTURE_SWIPE_UP = 64,
    GESTURE_SWIPE_DOWN = 128,
    GESTURE_PINCH_IN = 256,
    GESTURE_PINCH_OUT = 512
} Gestures;


typedef enum {
    CAMERA_CUSTOM = 0,
    CAMERA_FREE,
    CAMERA_ORBITAL,
    CAMERA_FIRST_PERSON,
    CAMERA_THIRD_PERSON
} CameraMode;


typedef enum {
    CAMERA_PERSPECTIVE = 0,
    CAMERA_ORTHOGRAPHIC
} CameraProjection;


typedef enum {
    NPATCH_NINE_PATCH = 0,
    NPATCH_THREE_PATCH_VERTICAL,
    NPATCH_THREE_PATCH_HORIZONTAL
} NPatchLayout;



typedef void (*TraceLogCallback)(int logLevel, const char *text, va_list args);
typedef unsigned char* (*LoadFileDataCallback)(const char* fileName, unsigned int* bytesRead);
typedef 
# 890 "raylib.h" 3 4
       _Bool 
# 890 "raylib.h"
            (*SaveFileDataCallback)(const char *fileName, void *data, unsigned int bytesToWrite);
typedef char *(*LoadFileTextCallback)(const char* fileName);
typedef 
# 892 "raylib.h" 3 4
       _Bool 
# 892 "raylib.h"
            (*SaveFileTextCallback)(const char *fileName, char *text);
# 909 "raylib.h"
 void InitWindow(int width, int height, const char *title);
 
# 910 "raylib.h" 3 4
     _Bool 
# 910 "raylib.h"
          WindowShouldClose(void);
 void CloseWindow(void);
 
# 912 "raylib.h" 3 4
     _Bool 
# 912 "raylib.h"
          IsWindowReady(void);
 
# 913 "raylib.h" 3 4
     _Bool 
# 913 "raylib.h"
          IsWindowFullscreen(void);
 
# 914 "raylib.h" 3 4
     _Bool 
# 914 "raylib.h"
          IsWindowHidden(void);
 
# 915 "raylib.h" 3 4
     _Bool 
# 915 "raylib.h"
          IsWindowMinimized(void);
 
# 916 "raylib.h" 3 4
     _Bool 
# 916 "raylib.h"
          IsWindowMaximized(void);
 
# 917 "raylib.h" 3 4
     _Bool 
# 917 "raylib.h"
          IsWindowFocused(void);
 
# 918 "raylib.h" 3 4
     _Bool 
# 918 "raylib.h"
          IsWindowResized(void);
 
# 919 "raylib.h" 3 4
     _Bool 
# 919 "raylib.h"
          IsWindowState(unsigned int flag);
 void SetWindowState(unsigned int flags);
 void ClearWindowState(unsigned int flags);
 void ToggleFullscreen(void);
 void MaximizeWindow(void);
 void MinimizeWindow(void);
 void RestoreWindow(void);
 void SetWindowIcon(Image image);
 void SetWindowTitle(const char *title);
 void SetWindowPosition(int x, int y);
 void SetWindowMonitor(int monitor);
 void SetWindowMinSize(int width, int height);
 void SetWindowSize(int width, int height);
 void *GetWindowHandle(void);
 int GetScreenWidth(void);
 int GetScreenHeight(void);
 int GetMonitorCount(void);
 int GetCurrentMonitor(void);
 Vector2 GetMonitorPosition(int monitor);
 int GetMonitorWidth(int monitor);
 int GetMonitorHeight(int monitor);
 int GetMonitorPhysicalWidth(int monitor);
 int GetMonitorPhysicalHeight(int monitor);
 int GetMonitorRefreshRate(int monitor);
 Vector2 GetWindowPosition(void);
 Vector2 GetWindowScaleDPI(void);
 const char *GetMonitorName(int monitor);
 void SetClipboardText(const char *text);
 const char *GetClipboardText(void);


 void ShowCursor(void);
 void HideCursor(void);
 
# 952 "raylib.h" 3 4
     _Bool 
# 952 "raylib.h"
          IsCursorHidden(void);
 void EnableCursor(void);
 void DisableCursor(void);
 
# 955 "raylib.h" 3 4
     _Bool 
# 955 "raylib.h"
          IsCursorOnScreen(void);


 void ClearBackground(Color color);
 void BeginDrawing(void);
 void EndDrawing(void);
 void BeginMode2D(Camera2D camera);
 void EndMode2D(void);
 void BeginMode3D(Camera3D camera);
 void EndMode3D(void);
 void BeginTextureMode(RenderTexture2D target);
 void EndTextureMode(void);
 void BeginShaderMode(Shader shader);
 void EndShaderMode(void);
 void BeginBlendMode(int mode);
 void EndBlendMode(void);
 void BeginScissorMode(int x, int y, int width, int height);
 void EndScissorMode(void);
 void BeginVrStereoMode(VrStereoConfig config);
 void EndVrStereoMode(void);


 VrStereoConfig LoadVrStereoConfig(VrDeviceInfo device);
 void UnloadVrStereoConfig(VrStereoConfig config);



 Shader LoadShader(const char *vsFileName, const char *fsFileName);
 Shader LoadShaderFromMemory(const char *vsCode, const char *fsCode);
 int GetShaderLocation(Shader shader, const char *uniformName);
 int GetShaderLocationAttrib(Shader shader, const char *attribName);
 void SetShaderValue(Shader shader, int locIndex, const void *value, int uniformType);
 void SetShaderValueV(Shader shader, int locIndex, const void *value, int uniformType, int count);
 void SetShaderValueMatrix(Shader shader, int locIndex, Matrix mat);
 void SetShaderValueTexture(Shader shader, int locIndex, Texture2D texture);
 void UnloadShader(Shader shader);


 Ray GetMouseRay(Vector2 mousePosition, Camera camera);
 Matrix GetCameraMatrix(Camera camera);
 Matrix GetCameraMatrix2D(Camera2D camera);
 Vector2 GetWorldToScreen(Vector3 position, Camera camera);
 Vector2 GetWorldToScreenEx(Vector3 position, Camera camera, int width, int height);
 Vector2 GetWorldToScreen2D(Vector2 position, Camera2D camera);
 Vector2 GetScreenToWorld2D(Vector2 position, Camera2D camera);


 void SetTargetFPS(int fps);
 int GetFPS(void);
 float GetFrameTime(void);
 double GetTime(void);


 int GetRandomValue(int min, int max);
 void TakeScreenshot(const char *fileName);
 void SetConfigFlags(unsigned int flags);

 void TraceLog(int logLevel, const char *text, ...);
 void SetTraceLogLevel(int logLevel);
 void *MemAlloc(int size);
 void *MemRealloc(void *ptr, int size);
 void MemFree(void *ptr);



 void SetTraceLogCallback(TraceLogCallback callback);
 void SetLoadFileDataCallback(LoadFileDataCallback callback);
 void SetSaveFileDataCallback(SaveFileDataCallback callback);
 void SetLoadFileTextCallback(LoadFileTextCallback callback);
 void SetSaveFileTextCallback(SaveFileTextCallback callback);


 unsigned char *LoadFileData(const char *fileName, unsigned int *bytesRead);
 void UnloadFileData(unsigned char *data);
 
# 1029 "raylib.h" 3 4
     _Bool 
# 1029 "raylib.h"
          SaveFileData(const char *fileName, void *data, unsigned int bytesToWrite);
 char *LoadFileText(const char *fileName);
 void UnloadFileText(unsigned char *text);
 
# 1032 "raylib.h" 3 4
     _Bool 
# 1032 "raylib.h"
          SaveFileText(const char *fileName, char *text);
 
# 1033 "raylib.h" 3 4
     _Bool 
# 1033 "raylib.h"
          FileExists(const char *fileName);
 
# 1034 "raylib.h" 3 4
     _Bool 
# 1034 "raylib.h"
          DirectoryExists(const char *dirPath);
 
# 1035 "raylib.h" 3 4
     _Bool 
# 1035 "raylib.h"
          IsFileExtension(const char *fileName, const char *ext);
 const char *GetFileExtension(const char *fileName);
 const char *GetFileName(const char *filePath);
 const char *GetFileNameWithoutExt(const char *filePath);
 const char *GetDirectoryPath(const char *filePath);
 const char *GetPrevDirectoryPath(const char *dirPath);
 const char *GetWorkingDirectory(void);
 char **GetDirectoryFiles(const char *dirPath, int *count);
 void ClearDirectoryFiles(void);
 
# 1044 "raylib.h" 3 4
     _Bool 
# 1044 "raylib.h"
          ChangeDirectory(const char *dir);
 
# 1045 "raylib.h" 3 4
     _Bool 
# 1045 "raylib.h"
          IsFileDropped(void);
 char **GetDroppedFiles(int *count);
 void ClearDroppedFiles(void);
 long GetFileModTime(const char *fileName);

 unsigned char *CompressData(unsigned char *data, int dataLength, int *compDataLength);
 unsigned char *DecompressData(unsigned char *compData, int compDataLength, int *dataLength);


 
# 1054 "raylib.h" 3 4
     _Bool 
# 1054 "raylib.h"
          SaveStorageValue(unsigned int position, int value);
 int LoadStorageValue(unsigned int position);

 void OpenURL(const char *url);






 
# 1064 "raylib.h" 3 4
     _Bool 
# 1064 "raylib.h"
          IsKeyPressed(int key);
 
# 1065 "raylib.h" 3 4
     _Bool 
# 1065 "raylib.h"
          IsKeyDown(int key);
 
# 1066 "raylib.h" 3 4
     _Bool 
# 1066 "raylib.h"
          IsKeyReleased(int key);
 
# 1067 "raylib.h" 3 4
     _Bool 
# 1067 "raylib.h"
          IsKeyUp(int key);
 void SetExitKey(int key);
 int GetKeyPressed(void);
 int GetCharPressed(void);


 
# 1073 "raylib.h" 3 4
     _Bool 
# 1073 "raylib.h"
          IsGamepadAvailable(int gamepad);
 
# 1074 "raylib.h" 3 4
     _Bool 
# 1074 "raylib.h"
          IsGamepadName(int gamepad, const char *name);
 const char *GetGamepadName(int gamepad);
 
# 1076 "raylib.h" 3 4
     _Bool 
# 1076 "raylib.h"
          IsGamepadButtonPressed(int gamepad, int button);
 
# 1077 "raylib.h" 3 4
     _Bool 
# 1077 "raylib.h"
          IsGamepadButtonDown(int gamepad, int button);
 
# 1078 "raylib.h" 3 4
     _Bool 
# 1078 "raylib.h"
          IsGamepadButtonReleased(int gamepad, int button);
 
# 1079 "raylib.h" 3 4
     _Bool 
# 1079 "raylib.h"
          IsGamepadButtonUp(int gamepad, int button);
 int GetGamepadButtonPressed(void);
 int GetGamepadAxisCount(int gamepad);
 float GetGamepadAxisMovement(int gamepad, int axis);
 int SetGamepadMappings(const char *mappings);


 
# 1086 "raylib.h" 3 4
     _Bool 
# 1086 "raylib.h"
          IsMouseButtonPressed(int button);
 
# 1087 "raylib.h" 3 4
     _Bool 
# 1087 "raylib.h"
          IsMouseButtonDown(int button);
 
# 1088 "raylib.h" 3 4
     _Bool 
# 1088 "raylib.h"
          IsMouseButtonReleased(int button);
 
# 1089 "raylib.h" 3 4
     _Bool 
# 1089 "raylib.h"
          IsMouseButtonUp(int button);
 int GetMouseX(void);
 int GetMouseY(void);
 Vector2 GetMousePosition(void);
 void SetMousePosition(int x, int y);
 void SetMouseOffset(int offsetX, int offsetY);
 void SetMouseScale(float scaleX, float scaleY);
 float GetMouseWheelMove(void);
 void SetMouseCursor(int cursor);


 int GetTouchX(void);
 int GetTouchY(void);
 Vector2 GetTouchPosition(int index);




 void SetGesturesEnabled(unsigned int flags);
 
# 1108 "raylib.h" 3 4
     _Bool 
# 1108 "raylib.h"
          IsGestureDetected(int gesture);
 int GetGestureDetected(void);
 int GetTouchPointsCount(void);
 float GetGestureHoldDuration(void);
 Vector2 GetGestureDragVector(void);
 float GetGestureDragAngle(void);
 Vector2 GetGesturePinchVector(void);
 float GetGesturePinchAngle(void);




 void SetCameraMode(Camera camera, int mode);
 void UpdateCamera(Camera *camera);

 void SetCameraPanControl(int keyPan);
 void SetCameraAltControl(int keyAlt);
 void SetCameraSmoothZoomControl(int keySmoothZoom);
 void SetCameraMoveControls(int keyFront, int keyBack, int keyRight, int keyLeft, int keyUp, int keyDown);







 void SetShapesTexture(Texture2D texture, Rectangle source);


 void DrawPixel(int posX, int posY, Color color);
 void DrawPixelV(Vector2 position, Color color);
 void DrawLine(int startPosX, int startPosY, int endPosX, int endPosY, Color color);
 void DrawLineV(Vector2 startPos, Vector2 endPos, Color color);
 void DrawLineEx(Vector2 startPos, Vector2 endPos, float thick, Color color);
 void DrawLineBezier(Vector2 startPos, Vector2 endPos, float thick, Color color);
 void DrawLineBezierQuad(Vector2 startPos, Vector2 endPos, Vector2 controlPos, float thick, Color color);
 void DrawLineStrip(Vector2 *points, int pointsCount, Color color);
 void DrawCircle(int centerX, int centerY, float radius, Color color);
 void DrawCircleSector(Vector2 center, float radius, float startAngle, float endAngle, int segments, Color color);
 void DrawCircleSectorLines(Vector2 center, float radius, float startAngle, float endAngle, int segments, Color color);
 void DrawCircleGradient(int centerX, int centerY, float radius, Color color1, Color color2);
 void DrawCircleV(Vector2 center, float radius, Color color);
 void DrawCircleLines(int centerX, int centerY, float radius, Color color);
 void DrawEllipse(int centerX, int centerY, float radiusH, float radiusV, Color color);
 void DrawEllipseLines(int centerX, int centerY, float radiusH, float radiusV, Color color);
 void DrawRing(Vector2 center, float innerRadius, float outerRadius, float startAngle, float endAngle, int segments, Color color);
 void DrawRingLines(Vector2 center, float innerRadius, float outerRadius, float startAngle, float endAngle, int segments, Color color);
 void DrawRectangle(int posX, int posY, int width, int height, Color color);
 void DrawRectangleV(Vector2 position, Vector2 size, Color color);
 void DrawRectangleRec(Rectangle rec, Color color);
 void DrawRectanglePro(Rectangle rec, Vector2 origin, float rotation, Color color);
 void DrawRectangleGradientV(int posX, int posY, int width, int height, Color color1, Color color2);
 void DrawRectangleGradientH(int posX, int posY, int width, int height, Color color1, Color color2);
 void DrawRectangleGradientEx(Rectangle rec, Color col1, Color col2, Color col3, Color col4);
 void DrawRectangleLines(int posX, int posY, int width, int height, Color color);
 void DrawRectangleLinesEx(Rectangle rec, int lineThick, Color color);
 void DrawRectangleRounded(Rectangle rec, float roundness, int segments, Color color);
 void DrawRectangleRoundedLines(Rectangle rec, float roundness, int segments, int lineThick, Color color);
 void DrawTriangle(Vector2 v1, Vector2 v2, Vector2 v3, Color color);
 void DrawTriangleLines(Vector2 v1, Vector2 v2, Vector2 v3, Color color);
 void DrawTriangleFan(Vector2 *points, int pointsCount, Color color);
 void DrawTriangleStrip(Vector2 *points, int pointsCount, Color color);
 void DrawPoly(Vector2 center, int sides, float radius, float rotation, Color color);
 void DrawPolyLines(Vector2 center, int sides, float radius, float rotation, Color color);


 
# 1174 "raylib.h" 3 4
     _Bool 
# 1174 "raylib.h"
          CheckCollisionRecs(Rectangle rec1, Rectangle rec2);
 
# 1175 "raylib.h" 3 4
     _Bool 
# 1175 "raylib.h"
          CheckCollisionCircles(Vector2 center1, float radius1, Vector2 center2, float radius2);
 
# 1176 "raylib.h" 3 4
     _Bool 
# 1176 "raylib.h"
          CheckCollisionCircleRec(Vector2 center, float radius, Rectangle rec);
 
# 1177 "raylib.h" 3 4
     _Bool 
# 1177 "raylib.h"
          CheckCollisionPointRec(Vector2 point, Rectangle rec);
 
# 1178 "raylib.h" 3 4
     _Bool 
# 1178 "raylib.h"
          CheckCollisionPointCircle(Vector2 point, Vector2 center, float radius);
 
# 1179 "raylib.h" 3 4
     _Bool 
# 1179 "raylib.h"
          CheckCollisionPointTriangle(Vector2 point, Vector2 p1, Vector2 p2, Vector2 p3);
 
# 1180 "raylib.h" 3 4
     _Bool 
# 1180 "raylib.h"
          CheckCollisionLines(Vector2 startPos1, Vector2 endPos1, Vector2 startPos2, Vector2 endPos2, Vector2 *collisionPoint);
 Rectangle GetCollisionRec(Rectangle rec1, Rectangle rec2);







 Image LoadImage(const char *fileName);
 Image LoadImageRaw(const char *fileName, int width, int height, int format, int headerSize);
 Image LoadImageAnim(const char *fileName, int *frames);
 Image LoadImageFromMemory(const char *fileType, const unsigned char *fileData, int dataSize);
 void UnloadImage(Image image);
 
# 1194 "raylib.h" 3 4
     _Bool 
# 1194 "raylib.h"
          ExportImage(Image image, const char *fileName);
 
# 1195 "raylib.h" 3 4
     _Bool 
# 1195 "raylib.h"
          ExportImageAsCode(Image image, const char *fileName);


 Image GenImageColor(int width, int height, Color color);
 Image GenImageGradientV(int width, int height, Color top, Color bottom);
 Image GenImageGradientH(int width, int height, Color left, Color right);
 Image GenImageGradientRadial(int width, int height, float density, Color inner, Color outer);
 Image GenImageChecked(int width, int height, int checksX, int checksY, Color col1, Color col2);
 Image GenImageWhiteNoise(int width, int height, float factor);
 Image GenImagePerlinNoise(int width, int height, int offsetX, int offsetY, float scale);
 Image GenImageCellular(int width, int height, int tileSize);


 Image ImageCopy(Image image);
 Image ImageFromImage(Image image, Rectangle rec);
 Image ImageText(const char *text, int fontSize, Color color);
 Image ImageTextEx(Font font, const char *text, float fontSize, float spacing, Color tint);
 void ImageFormat(Image *image, int newFormat);
 void ImageToPOT(Image *image, Color fill);
 void ImageCrop(Image *image, Rectangle crop);
 void ImageAlphaCrop(Image *image, float threshold);
 void ImageAlphaClear(Image *image, Color color, float threshold);
 void ImageAlphaMask(Image *image, Image alphaMask);
 void ImageAlphaPremultiply(Image *image);
 void ImageResize(Image *image, int newWidth, int newHeight);
 void ImageResizeNN(Image *image, int newWidth,int newHeight);
 void ImageResizeCanvas(Image *image, int newWidth, int newHeight, int offsetX, int offsetY, Color fill);
 void ImageMipmaps(Image *image);
 void ImageDither(Image *image, int rBpp, int gBpp, int bBpp, int aBpp);
 void ImageFlipVertical(Image *image);
 void ImageFlipHorizontal(Image *image);
 void ImageRotateCW(Image *image);
 void ImageRotateCCW(Image *image);
 void ImageColorTint(Image *image, Color color);
 void ImageColorInvert(Image *image);
 void ImageColorGrayscale(Image *image);
 void ImageColorContrast(Image *image, float contrast);
 void ImageColorBrightness(Image *image, int brightness);
 void ImageColorReplace(Image *image, Color color, Color replace);
 Color *LoadImageColors(Image image);
 Color *LoadImagePalette(Image image, int maxPaletteSize, int *colorsCount);
 void UnloadImageColors(Color *colors);
 void UnloadImagePalette(Color *colors);
 Rectangle GetImageAlphaBorder(Image image, float threshold);



 void ImageClearBackground(Image *dst, Color color);
 void ImageDrawPixel(Image *dst, int posX, int posY, Color color);
 void ImageDrawPixelV(Image *dst, Vector2 position, Color color);
 void ImageDrawLine(Image *dst, int startPosX, int startPosY, int endPosX, int endPosY, Color color);
 void ImageDrawLineV(Image *dst, Vector2 start, Vector2 end, Color color);
 void ImageDrawCircle(Image *dst, int centerX, int centerY, int radius, Color color);
 void ImageDrawCircleV(Image *dst, Vector2 center, int radius, Color color);
 void ImageDrawRectangle(Image *dst, int posX, int posY, int width, int height, Color color);
 void ImageDrawRectangleV(Image *dst, Vector2 position, Vector2 size, Color color);
 void ImageDrawRectangleRec(Image *dst, Rectangle rec, Color color);
 void ImageDrawRectangleLines(Image *dst, Rectangle rec, int thick, Color color);
 void ImageDraw(Image *dst, Image src, Rectangle srcRec, Rectangle dstRec, Color tint);
 void ImageDrawText(Image *dst, const char *text, int posX, int posY, int fontSize, Color color);
 void ImageDrawTextEx(Image *dst, Font font, const char *text, Vector2 position, float fontSize, float spacing, Color tint);



 Texture2D LoadTexture(const char *fileName);
 Texture2D LoadTextureFromImage(Image image);
 TextureCubemap LoadTextureCubemap(Image image, int layout);
 RenderTexture2D LoadRenderTexture(int width, int height);
 void UnloadTexture(Texture2D texture);
 void UnloadRenderTexture(RenderTexture2D target);
 void UpdateTexture(Texture2D texture, const void *pixels);
 void UpdateTextureRec(Texture2D texture, Rectangle rec, const void *pixels);
 Image GetTextureData(Texture2D texture);
 Image GetScreenData(void);


 void GenTextureMipmaps(Texture2D *texture);
 void SetTextureFilter(Texture2D texture, int filter);
 void SetTextureWrap(Texture2D texture, int wrap);


 void DrawTexture(Texture2D texture, int posX, int posY, Color tint);
 void DrawTextureV(Texture2D texture, Vector2 position, Color tint);
 void DrawTextureEx(Texture2D texture, Vector2 position, float rotation, float scale, Color tint);
 void DrawTextureRec(Texture2D texture, Rectangle source, Vector2 position, Color tint);
 void DrawTextureQuad(Texture2D texture, Vector2 tiling, Vector2 offset, Rectangle quad, Color tint);
 void DrawTextureTiled(Texture2D texture, Rectangle source, Rectangle dest, Vector2 origin, float rotation, float scale, Color tint);
 void DrawTexturePro(Texture2D texture, Rectangle source, Rectangle dest, Vector2 origin, float rotation, Color tint);
 void DrawTextureNPatch(Texture2D texture, NPatchInfo nPatchInfo, Rectangle dest, Vector2 origin, float rotation, Color tint);
 void DrawTexturePoly(Texture2D texture, Vector2 center, Vector2 *points, Vector2 *texcoords, int pointsCount, Color tint);


 Color Fade(Color color, float alpha);
 int ColorToInt(Color color);
 Vector4 ColorNormalize(Color color);
 Color ColorFromNormalized(Vector4 normalized);
 Vector3 ColorToHSV(Color color);
 Color ColorFromHSV(float hue, float saturation, float value);
 Color ColorAlpha(Color color, float alpha);
 Color ColorAlphaBlend(Color dst, Color src, Color tint);
 Color GetColor(int hexValue);
 Color GetPixelColor(void *srcPtr, int format);
 void SetPixelColor(void *dstPtr, Color color, int format);
 int GetPixelDataSize(int width, int height, int format);






 Font GetFontDefault(void);
 Font LoadFont(const char *fileName);
 Font LoadFontEx(const char *fileName, int fontSize, int *fontChars, int charsCount);
 Font LoadFontFromImage(Image image, Color key, int firstChar);
 Font LoadFontFromMemory(const char *fileType, const unsigned char *fileData, int dataSize, int fontSize, int *fontChars, int charsCount);
 CharInfo *LoadFontData(const unsigned char *fileData, int dataSize, int fontSize, int *fontChars, int charsCount, int type);
 Image GenImageFontAtlas(const CharInfo *chars, Rectangle **recs, int charsCount, int fontSize, int padding, int packMethod);
 void UnloadFontData(CharInfo *chars, int charsCount);
 void UnloadFont(Font font);


 void DrawFPS(int posX, int posY);
 void DrawText(const char *text, int posX, int posY, int fontSize, Color color);
 void DrawTextEx(Font font, const char *text, Vector2 position, float fontSize, float spacing, Color tint);
 void DrawTextRec(Font font, const char *text, Rectangle rec, float fontSize, float spacing, 
# 1319 "raylib.h" 3 4
                                                                                                 _Bool 
# 1319 "raylib.h"
                                                                                                      wordWrap, Color tint);
 void DrawTextRecEx(Font font, const char *text, Rectangle rec, float fontSize, float spacing, 
# 1320 "raylib.h" 3 4
                                                                                                   _Bool 
# 1320 "raylib.h"
                                                                                                        wordWrap, Color tint,
                         int selectStart, int selectLength, Color selectTint, Color selectBackTint);
 void DrawTextCodepoint(Font font, int codepoint, Vector2 position, float fontSize, Color tint);


 int MeasureText(const char *text, int fontSize);
 Vector2 MeasureTextEx(Font font, const char *text, float fontSize, float spacing);
 int GetGlyphIndex(Font font, int codepoint);



 int TextCopy(char *dst, const char *src);
 
# 1332 "raylib.h" 3 4
     _Bool 
# 1332 "raylib.h"
          TextIsEqual(const char *text1, const char *text2);
 unsigned int TextLength(const char *text);
 const char *TextFormat(const char *text, ...);
 const char *TextSubtext(const char *text, int position, int length);
 char *TextReplace(char *text, const char *replace, const char *by);
 char *TextInsert(const char *text, const char *insert, int position);
 const char *TextJoin(const char **textList, int count, const char *delimiter);
 const char **TextSplit(const char *text, char delimiter, int *count);
 void TextAppend(char *text, const char *append, int *position);
 int TextFindIndex(const char *text, const char *find);
 const char *TextToUpper(const char *text);
 const char *TextToLower(const char *text);
 const char *TextToPascal(const char *text);
 int TextToInteger(const char *text);
 char *TextToUtf8(int *codepoints, int length);


 int *GetCodepoints(const char *text, int *count);
 int GetCodepointsCount(const char *text);
 int GetNextCodepoint(const char *text, int *bytesProcessed);
 const char *CodepointToUtf8(int codepoint, int *byteLength);






 void DrawLine3D(Vector3 startPos, Vector3 endPos, Color color);
 void DrawPoint3D(Vector3 position, Color color);
 void DrawCircle3D(Vector3 center, float radius, Vector3 rotationAxis, float rotationAngle, Color color);
 void DrawTriangle3D(Vector3 v1, Vector3 v2, Vector3 v3, Color color);
 void DrawTriangleStrip3D(Vector3 *points, int pointsCount, Color color);
 void DrawCube(Vector3 position, float width, float height, float length, Color color);
 void DrawCubeV(Vector3 position, Vector3 size, Color color);
 void DrawCubeWires(Vector3 position, float width, float height, float length, Color color);
 void DrawCubeWiresV(Vector3 position, Vector3 size, Color color);
 void DrawCubeTexture(Texture2D texture, Vector3 position, float width, float height, float length, Color color);
 void DrawSphere(Vector3 centerPos, float radius, Color color);
 void DrawSphereEx(Vector3 centerPos, float radius, int rings, int slices, Color color);
 void DrawSphereWires(Vector3 centerPos, float radius, int rings, int slices, Color color);
 void DrawCylinder(Vector3 position, float radiusTop, float radiusBottom, float height, int slices, Color color);
 void DrawCylinderWires(Vector3 position, float radiusTop, float radiusBottom, float height, int slices, Color color);
 void DrawPlane(Vector3 centerPos, Vector2 size, Color color);
 void DrawRay(Ray ray, Color color);
 void DrawGrid(int slices, float spacing);






 Model LoadModel(const char *fileName);
 Model LoadModelFromMesh(Mesh mesh);
 void UnloadModel(Model model);
 void UnloadModelKeepMeshes(Model model);


 void UploadMesh(Mesh *mesh, 
# 1389 "raylib.h" 3 4
                                 _Bool 
# 1389 "raylib.h"
                                      dynamic);
 void UpdateMeshBuffer(Mesh mesh, int index, void *data, int dataSize, int offset);
 void DrawMesh(Mesh mesh, Material material, Matrix transform);
 void DrawMeshInstanced(Mesh mesh, Material material, Matrix *transforms, int instances);
 void UnloadMesh(Mesh mesh);
 
# 1394 "raylib.h" 3 4
     _Bool 
# 1394 "raylib.h"
          ExportMesh(Mesh mesh, const char *fileName);


 Material *LoadMaterials(const char *fileName, int *materialCount);
 Material LoadMaterialDefault(void);
 void UnloadMaterial(Material material);
 void SetMaterialTexture(Material *material, int mapType, Texture2D texture);
 void SetModelMeshMaterial(Model *model, int meshId, int materialId);


 ModelAnimation *LoadModelAnimations(const char *fileName, int *animsCount);
 void UpdateModelAnimation(Model model, ModelAnimation anim, int frame);
 void UnloadModelAnimation(ModelAnimation anim);
 void UnloadModelAnimations(ModelAnimation* animations, unsigned int count);
 
# 1408 "raylib.h" 3 4
     _Bool 
# 1408 "raylib.h"
          IsModelAnimationValid(Model model, ModelAnimation anim);


 Mesh GenMeshPoly(int sides, float radius);
 Mesh GenMeshPlane(float width, float length, int resX, int resZ);
 Mesh GenMeshCube(float width, float height, float length);
 Mesh GenMeshSphere(float radius, int rings, int slices);
 Mesh GenMeshHemiSphere(float radius, int rings, int slices);
 Mesh GenMeshCylinder(float radius, float height, int slices);
 Mesh GenMeshTorus(float radius, float size, int radSeg, int sides);
 Mesh GenMeshKnot(float radius, float size, int radSeg, int sides);
 Mesh GenMeshHeightmap(Image heightmap, Vector3 size);
 Mesh GenMeshCubicmap(Image cubicmap, Vector3 cubeSize);


 BoundingBox MeshBoundingBox(Mesh mesh);
 void MeshTangents(Mesh *mesh);
 void MeshBinormals(Mesh *mesh);


 void DrawModel(Model model, Vector3 position, float scale, Color tint);
 void DrawModelEx(Model model, Vector3 position, Vector3 rotationAxis, float rotationAngle, Vector3 scale, Color tint);
 void DrawModelWires(Model model, Vector3 position, float scale, Color tint);
 void DrawModelWiresEx(Model model, Vector3 position, Vector3 rotationAxis, float rotationAngle, Vector3 scale, Color tint);
 void DrawBoundingBox(BoundingBox box, Color color);
 void DrawBillboard(Camera camera, Texture2D texture, Vector3 center, float size, Color tint);
 void DrawBillboardRec(Camera camera, Texture2D texture, Rectangle source, Vector3 center, float size, Color tint);


 
# 1437 "raylib.h" 3 4
     _Bool 
# 1437 "raylib.h"
          CheckCollisionSpheres(Vector3 center1, float radius1, Vector3 center2, float radius2);
 
# 1438 "raylib.h" 3 4
     _Bool 
# 1438 "raylib.h"
          CheckCollisionBoxes(BoundingBox box1, BoundingBox box2);
 
# 1439 "raylib.h" 3 4
     _Bool 
# 1439 "raylib.h"
          CheckCollisionBoxSphere(BoundingBox box, Vector3 center, float radius);
 
# 1440 "raylib.h" 3 4
     _Bool 
# 1440 "raylib.h"
          CheckCollisionRaySphere(Ray ray, Vector3 center, float radius);
 
# 1441 "raylib.h" 3 4
     _Bool 
# 1441 "raylib.h"
          CheckCollisionRaySphereEx(Ray ray, Vector3 center, float radius, Vector3 *collisionPoint);
 
# 1442 "raylib.h" 3 4
     _Bool 
# 1442 "raylib.h"
          CheckCollisionRayBox(Ray ray, BoundingBox box);
 RayHitInfo GetCollisionRayMesh(Ray ray, Mesh mesh, Matrix transform);
 RayHitInfo GetCollisionRayModel(Ray ray, Model model);
 RayHitInfo GetCollisionRayTriangle(Ray ray, Vector3 p1, Vector3 p2, Vector3 p3);
 RayHitInfo GetCollisionRayGround(Ray ray, float groundHeight);






 void InitAudioDevice(void);
 void CloseAudioDevice(void);
 
# 1455 "raylib.h" 3 4
     _Bool 
# 1455 "raylib.h"
          IsAudioDeviceReady(void);
 void SetMasterVolume(float volume);


 Wave LoadWave(const char *fileName);
 Wave LoadWaveFromMemory(const char *fileType, const unsigned char *fileData, int dataSize);
 Sound LoadSound(const char *fileName);
 Sound LoadSoundFromWave(Wave wave);
 void UpdateSound(Sound sound, const void *data, int samplesCount);
 void UnloadWave(Wave wave);
 void UnloadSound(Sound sound);
 
# 1466 "raylib.h" 3 4
     _Bool 
# 1466 "raylib.h"
          ExportWave(Wave wave, const char *fileName);
 
# 1467 "raylib.h" 3 4
     _Bool 
# 1467 "raylib.h"
          ExportWaveAsCode(Wave wave, const char *fileName);


 void PlaySound(Sound sound);
 void StopSound(Sound sound);
 void PauseSound(Sound sound);
 void ResumeSound(Sound sound);
 void PlaySoundMulti(Sound sound);
 void StopSoundMulti(void);
 int GetSoundsPlaying(void);
 
# 1477 "raylib.h" 3 4
     _Bool 
# 1477 "raylib.h"
          IsSoundPlaying(Sound sound);
 void SetSoundVolume(Sound sound, float volume);
 void SetSoundPitch(Sound sound, float pitch);
 void WaveFormat(Wave *wave, int sampleRate, int sampleSize, int channels);
 Wave WaveCopy(Wave wave);
 void WaveCrop(Wave *wave, int initSample, int finalSample);
 float *LoadWaveSamples(Wave wave);
 void UnloadWaveSamples(float *samples);


 Music LoadMusicStream(const char *fileName);
 Music LoadMusicStreamFromMemory(const char *fileType, unsigned char* data, int dataSize);
 void UnloadMusicStream(Music music);
 void PlayMusicStream(Music music);
 
# 1491 "raylib.h" 3 4
     _Bool 
# 1491 "raylib.h"
          IsMusicPlaying(Music music);
 void UpdateMusicStream(Music music);
 void StopMusicStream(Music music);
 void PauseMusicStream(Music music);
 void ResumeMusicStream(Music music);
 void SetMusicVolume(Music music, float volume);
 void SetMusicPitch(Music music, float pitch);
 float GetMusicTimeLength(Music music);
 float GetMusicTimePlayed(Music music);


 AudioStream InitAudioStream(unsigned int sampleRate, unsigned int sampleSize, unsigned int channels);
 void UpdateAudioStream(AudioStream stream, const void *data, int samplesCount);
 void CloseAudioStream(AudioStream stream);
 
# 1505 "raylib.h" 3 4
     _Bool 
# 1505 "raylib.h"
          IsAudioStreamProcessed(AudioStream stream);
 void PlayAudioStream(AudioStream stream);
 void PauseAudioStream(AudioStream stream);
 void ResumeAudioStream(AudioStream stream);
 
# 1509 "raylib.h" 3 4
     _Bool 
# 1509 "raylib.h"
          IsAudioStreamPlaying(AudioStream stream);
 void StopAudioStream(AudioStream stream);
 void SetAudioStreamVolume(AudioStream stream, float volume);
 void SetAudioStreamPitch(AudioStream stream, float pitch);
 void SetAudioStreamBufferSizeDefault(int size);
