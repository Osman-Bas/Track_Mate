import mongoose from 'mongoose';
const Schema = mongoose.Schema;

// Görev şemasını (veritabanı yapısını) tanımlıyoruz
// Bu, Swift'teki 'TaskItem' struct'ının karşılığıdır
const TaskSchema = new Schema({
    // BU GÖREV HANGİ KULLANICIYA AİT?
    // Bu, sistemin en önemli parçasıdır. User modelimize bir referans (ilişki).
    user: {
        type: Schema.Types.ObjectId, // Kullanıcının benzersiz MongoDB ID'si
        ref: 'User', // 'User' modeline bağlı
        required: true
    },
    // Swift'ten gelen 'title' alanı
    title: {
        type: String,
        required: [true, 'Lütfen bir başlık girin.'],
        trim: true
    },
    // Swift'ten gelen 'description' alanı
    description: {
        type: String,
        default: ''
    },
    // Swift'teki 'isCompleted' alanı (DashboardView'da gördüm)
    isCompleted: {
        type: Boolean,
        default: false // Yeni görev varsayılan olarak tamamlanmamış
    },
    // Swift'ten gelen 'date' alanı (Görevin tarihi/zamanı)
    date: {
        type: Date,
        default: Date.now
    },
    // Swift'teki 'TaskPriority' enum'unun karşılığı
    // ('low', 'medium', 'high')
    priority: {
        type: String,
        enum: ['Düşük', 'Orta', 'Yüksek'], // Sadece bu değerleri alabilir
        default: 'Orta'
    }
}, {
    // 'createdAt' (oluşturulma) ve 'updatedAt' (güncellenme)
    // zaman damgalarını otomatik olarak ekle
    timestamps: true
});

// Şemayı bir model olarak dışa aktarıyoruz (ESM formatında)
// 'Task' adı, veritabanında 'tasks' adında bir koleksiyon oluşturacak
export default mongoose.model('Task', TaskSchema);