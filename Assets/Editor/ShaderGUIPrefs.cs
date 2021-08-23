using UnityEditor;

namespace URPToon
{
    public static class ShaderGUIPrefs
    {
        private static string EditorPrefKey = "URPToonShaderGUI";
        public static bool GetFoldoutState(MaterialEditor materialEditor,string name)
        {
            // Get value from EditorPrefs
            return EditorPrefs.GetBool($"{EditorPrefKey}.{name + materialEditor.GetInstanceID()}");
        }

        public static void SetFoldoutState(MaterialEditor materialEditor, string name, bool field, bool value)
        {
            if (field == value)
                return;

            // Set value to EditorPrefs and field
            EditorPrefs.SetBool($"{EditorPrefKey}.{name + materialEditor.GetInstanceID()}", value);
        }
    }
}