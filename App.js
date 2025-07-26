import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, Button, StyleSheet } from 'react-native';
import Voice from 'react-native-voice';
import Tts from 'react-native-tts';
import { Picker } from '@react-native-picker/picker';
import axios from 'axios';

const LANGUAGES = [
  { label: 'İngilizce', value: 'en' },
  { label: 'Türkçe', value: 'tr' },
  { label: 'Almanca', value: 'de' },
  { label: 'Fransızca', value: 'fr' },
];

export default function App() {
  const [inputText, setInputText] = useState('');
  const [translatedText, setTranslatedText] = useState('');
  const [fromLang, setFromLang] = useState('tr');
  const [toLang, setToLang] = useState('en');
  const [isRecording, setIsRecording] = useState(false);

  const startRecording = async () => {
    setIsRecording(true);
    try {
      await Voice.start(fromLang);
    } catch (e) {
      setIsRecording(false);
    }
  };

  const stopRecording = async () => {
    setIsRecording(false);
    try {
      await Voice.stop();
    } catch (e) {}
  };

  useEffect(() => {
    Voice.onSpeechResults = (e) => {
      setInputText(e.value[0]);
      setIsRecording(false);
    };
    return () => {
      Voice.destroy().then(Voice.removeAllListeners);
    };
  }, []);

  const translateText = async () => {
    try {
      const res = await axios.post('https://libretranslate.de/translate', {
        q: inputText,
        source: fromLang,
        target: toLang,
        format: 'text',
      });
      setTranslatedText(res.data.translatedText);
    } catch (e) {
      setTranslatedText('Çeviri başarısız.');
    }
  };

  const speak = (text, lang) => {
    Tts.setDefaultLanguage(lang);
    Tts.speak(text);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Voice Translator</Text>
      <View style={styles.row}>
        <Picker
          selectedValue={fromLang}
          style={styles.picker}
          onValueChange={setFromLang}>
          {LANGUAGES.map(l => <Picker.Item key={l.value} label={l.label} value={l.value} />)}
        </Picker>
        <Text>→</Text>
        <Picker
          selectedValue={toLang}
          style={styles.picker}
          onValueChange={setToLang}>
          {LANGUAGES.map(l => <Picker.Item key={l.value} label={l.label} value={l.value} />)}
        </Picker>
      </View>
      <TextInput
        style={styles.input}
        placeholder="Metin girin veya konuşun"
        value={inputText}
        onChangeText={setInputText}
        multiline
      />
      <View style={styles.row}>
        <Button title={isRecording ? "Dinleniyor..." : "Konuş"} onPress={isRecording ? stopRecording : startRecording} />
        <Button title="Çevir" onPress={translateText} />
        <Button title="Oku" onPress={() => speak(inputText, fromLang)} />
      </View>
      <Text style={styles.label}>Çeviri:</Text>
      <Text style={styles.translated}>{translatedText}</Text>
      <Button title="Çeviriyi Oku" onPress={() => speak(translatedText, toLang)} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20, justifyContent: 'center' },
  title: { fontSize: 28, fontWeight: 'bold', textAlign: 'center', marginBottom: 20 },
  row: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginVertical: 10 },
  picker: { flex: 1, height: 50 },
  input: { borderWidth: 1, borderColor: '#ccc', borderRadius: 8, padding: 10, minHeight: 60, marginVertical: 10 },
  label: { fontWeight: 'bold', marginTop: 20 },
  translated: { fontSize: 18, marginVertical: 10 }
}); 